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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
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

pragma solidity ^0.8.14;

abstract contract Services {

    enum TokenType {
        STANDARD,
        MINTABLE,
        BURNABLE,
        PAUSEABLE,
        BLACKLIST,
        DEFLATION,
        SUPER_DEFLAIONS
    }

    event ExtraFeeRefund(
        address receiver,
        uint256 amountReceived,
        uint256 amountRefund
    );

    function refundExtraServiceFee(address to,uint256 value, uint256 fee) internal {
        require(to != address(0), "Services: Invalid address");

        uint256 refundAmount = value- fee;
        payable(to).transfer(refundAmount);

        emit ExtraFeeRefund(to, value, fee);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC20Mintable
 * @dev Implementation of the ERC20Mintable. Extension of {ERC20} that adds a minting behaviour.
 */
abstract contract ERC20Mintable is ERC20 {
    // indicates if minting is finished
    bool private _mintingFinished = false;

    /**
     * @dev Emitted during finish minting
     */
    event MintFinished();

    /**
     * @dev Tokens can be minted only before minting finished.
     */
    modifier canMint() {
        require(!_mintingFinished, "ERC20Mintable: minting is finished");
        _;
    }

    /**
     * @return if minting is finished or not.
     */
    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }

    /**
     * @dev Function to mint tokens.
     *
     * WARNING: it allows everyone to mint new tokens. Access controls MUST be defined in derived contracts.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address account, uint256 amount) public canMint {
        _mint(account, amount);
    }

    /**
     * @dev Function to stop minting new tokens.
     *
     * WARNING: it allows everyone to finish minting. Access controls MUST be defined in derived contracts.
     */
    function finishMinting() public canMint {
        _finishMinting();
    }

    /**
     * @dev Function to stop minting new tokens.
     */
    function _finishMinting() internal virtual {
        _mintingFinished = true;

        emit MintFinished();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "contracts/service/Services.sol";
import "contracts/uniswapV2Interface/IUniswapV2Router02.sol";
import "contracts/uniswapV2Interface/IUniswapV2Factory.sol";
import "contracts/uniswapV2Interface/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../../behaviours/ERC20Mintable.sol";


contract MintBurnSuperDeflation is ERC20,ERC20Mintable, ERC20Capped, ERC20Burnable, Ownable, Services {
    // CONFIG START

    uint8 private _decimals;
    uint256 private initialSupply;
    address private tokenOwner;

    uint256 private denominator = 100;

    uint256 private swapThreshold = 0.0000005 ether; // The contract will only swap to ETH, once the fee tokens reach the specified threshold

    uint256 private devTaxBuy;
    uint256 private marketingTaxBuy;
    uint256 private liquidityTaxBuy;
    uint256 private charityTaxBuy;

    uint256 private devTaxSell;
    uint256 private marketingTaxSell;
    uint256 private liquidityTaxSell;
    uint256 private charityTaxSell;

    address private devTaxWallet;
    address private marketingTaxWallet;
    address private liquidityTaxWallet;
    address private charityTaxWallet;

    // CONFIG END

    mapping(address => bool) private excludeList;

    mapping(string => uint256) private buyTaxes;
    mapping(string => uint256) private sellTaxes;
    mapping(string => address) private taxWallets;

    bool public taxStatus = true;

    IUniswapV2Router02 private uniswapV2Router02;
    IUniswapV2Factory private uniswapV2Factory;
    IUniswapV2Pair private uniswapV2Pair;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 decimals_,
        uint256 _supply,
        address[6] memory _addr,
        uint256[8] memory _value,
        uint256 _cap,
        bool _isCustomOwner,
        uint256 serviceFee
    ) payable ERC20(_tokenName, _tokenSymbol) ERC20Capped(_cap) {
        require(_supply <= _cap, "SuperDefltion: Cap exceeded");
        require(msg.value >= serviceFee, "SuperDeflation: Insufficient service fee");
        _decimals = decimals_;
        initialSupply = _supply;
        _mint(msg.sender, initialSupply);
        uniswapV2Router02 = IUniswapV2Router02(_addr[1]);
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Router02.factory());
        uniswapV2Pair = IUniswapV2Pair(
            uniswapV2Factory.createPair(address(this), uniswapV2Router02.WETH())
        );
        taxWallets["liquidity"] = _addr[0];
        setBuyTax(_value[0], _value[1], _value[3], _value[2]);
        setSellTax(_value[4], _value[5], _value[7], _value[6]);
        setTaxWallets(_addr[2], _addr[3], _addr[4]);
       tokenOwner = _isCustomOwner ? _addr[5] : _msgSender();
        exclude(tokenOwner);
        exclude(address(this));
        payable(_addr[0]).transfer(serviceFee);
        if (msg.value > serviceFee) refundExtraServiceFee(_msgSender(), msg.value, serviceFee);
        if (tokenOwner != _msgSender()) {
            _transferOwnership(_addr[5]);
        }
    }

    uint256 private marketingTokens;
    uint256 private devTokens;
    uint256 private liquidityTokens;
    uint256 private charityTokens;

    /**
     * @dev Calculates the tax, transfer it to the contract. If the user is selling, and the swap threshold is met, it executes the tax.
     */
    function handleTax(
        address from,
        address to,
        uint256 amount
    ) private returns (uint256) {
        address[] memory sellPath = new address[](2);
        sellPath[0] = address(this);
        sellPath[1] = uniswapV2Router02.WETH();

        if (!isExcluded(from) && !isExcluded(to)) {
            uint256 tax;
            uint256 baseUnit = amount / denominator;
            if (from == address(uniswapV2Pair)) {
                tax += baseUnit * buyTaxes["marketing"];
                tax += baseUnit * buyTaxes["dev"];
                tax += baseUnit * buyTaxes["liquidity"];
                tax += baseUnit * buyTaxes["charity"];

                if (tax > 0) {
                    _transfer(from, address(this), tax);
                }

                marketingTokens += baseUnit * buyTaxes["marketing"];
                devTokens += baseUnit * buyTaxes["dev"];
                liquidityTokens += baseUnit * buyTaxes["liquidity"];
                charityTokens += baseUnit * buyTaxes["charity"];
            } else if (to == address(uniswapV2Pair)) {
                tax += baseUnit * sellTaxes["marketing"];
                tax += baseUnit * sellTaxes["dev"];
                tax += baseUnit * sellTaxes["liquidity"];
                tax += baseUnit * sellTaxes["charity"];

                if (tax > 0) {
                    _transfer(from, address(this), tax);
                }

                marketingTokens += baseUnit * sellTaxes["marketing"];
                devTokens += baseUnit * sellTaxes["dev"];
                liquidityTokens += baseUnit * sellTaxes["liquidity"];
                charityTokens += baseUnit * sellTaxes["charity"];

                uint256 taxSum = marketingTokens +
                    devTokens +
                    liquidityTokens +
                    charityTokens;

                if (taxSum == 0) return amount;

                uint256 ethValue = uniswapV2Router02.getAmountsOut(
                    marketingTokens +
                        devTokens +
                        liquidityTokens +
                        charityTokens,
                    sellPath
                )[1];

                if (ethValue >= swapThreshold) {
                    uint256 startBalance = address(this).balance;

                    uint256 toSell = marketingTokens +
                        devTokens +
                        liquidityTokens /
                        2 +
                        charityTokens;

                    _approve(address(this), address(uniswapV2Router02), toSell);

                    uniswapV2Router02.swapExactTokensForETH(
                        toSell,
                        0,
                        sellPath,
                        address(this),
                        block.timestamp
                    );

                    uint256 ethGained = address(this).balance - startBalance;

                    uint256 liquidityToken = liquidityTokens / 2;
                    uint256 liquidityETH = (ethGained *
                        (((liquidityTokens / 2) * 10 ** 18) / taxSum)) /
                        10 ** 18;

                    uint256 marketingETH = (ethGained *
                        ((marketingTokens * 10 ** 18) / taxSum)) / 10 ** 18;
                    uint256 devETH = (ethGained *
                        ((devTokens * 10 ** 18) / taxSum)) / 10 ** 18;
                    uint256 charityETH = (ethGained *
                        ((charityTokens * 10 ** 18) / taxSum)) / 10 ** 18;

                    _approve(
                        address(this),
                        address(uniswapV2Router02),
                        liquidityToken
                    );

                    (
                        uint amountToken,
                        uint amountETH,
                        uint liquidity
                    ) = uniswapV2Router02.addLiquidityETH{value: liquidityETH}(
                            address(this),
                            liquidityToken,
                            0,
                            0,
                            taxWallets["liquidity"],
                            block.timestamp
                        );

                    uint256 remainingTokens = (marketingTokens +
                        devTokens +
                        liquidityTokens +
                        charityTokens) - (toSell + amountToken);

                    if (remainingTokens > 0) {
                        _transfer(
                            address(this),
                            taxWallets["dev"],
                            remainingTokens
                        );
                    }

                    taxWallets["marketing"].call{value: marketingETH}("");
                    taxWallets["dev"].call{value: devETH}("");
                    taxWallets["charity"].call{value: charityETH}("");

                    if (
                        ethGained -
                            (marketingETH +
                                devETH +
                                liquidityETH +
                                charityETH) >
                        0
                    ) {
                        taxWallets["marketing"].call{
                            value: ethGained -
                                (marketingETH +
                                    devETH +
                                    liquidityETH +
                                    charityETH)
                        }("");
                    }

                    marketingTokens = 0;
                    devTokens = 0;
                    liquidityTokens = 0;
                    charityTokens = 0;
                }
            }

            amount -= tax;
        }

        return amount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (taxStatus) {
            amount = handleTax(sender, recipient, amount);
        }

        super._transfer(sender, recipient, amount);
    }

    /**
     * @dev Triggers the tax handling functionality
     */
    function triggerTax() public onlyOwner {
        handleTax(address(0), address(uniswapV2Pair), 0);
    }

    /**
     * @dev Excludes the specified account from tax.
     */
    function exclude(address account) public onlyOwner {
        require(!isExcluded(account), "SuperDeflation: Account is already excluded");
        excludeList[account] = true;
    }

    /**
     * @dev Re-enables tax on the specified account.
     */
    function removeExclude(address account) public onlyOwner {
        require(isExcluded(account), "SuperDeflation: Account is not excluded");
        excludeList[account] = false;
    }

    /**
     * @dev Sets tax for buys.
     */
    function setBuyTax(
        uint256 dev,
        uint256 marketing,
        uint256 liquidity,
        uint256 charity
    ) public onlyOwner {
        buyTaxes["dev"] = dev;
        buyTaxes["marketing"] = marketing;
        buyTaxes["liquidity"] = liquidity;
        buyTaxes["charity"] = charity;
    }

    /**
     * @dev Sets tax for sells.
     */
    function setSellTax(
        uint256 dev,
        uint256 marketing,
        uint256 liquidity,
        uint256 charity
    ) public onlyOwner {
        sellTaxes["dev"] = dev;
        sellTaxes["marketing"] = marketing;
        sellTaxes["liquidity"] = liquidity;
        sellTaxes["charity"] = charity;
    }

    /**
     * @dev Sets wallets for taxes.
     */
    function setTaxWallets(
        address dev,
        address marketing,
        address charity
    ) public onlyOwner {
        taxWallets["dev"] = dev;
        taxWallets["marketing"] = marketing;
        taxWallets["charity"] = charity;
    }

    /**
     * @dev Enables tax globally.
     */
    function enableTax() public onlyOwner {
        require(!taxStatus, "SuperDeflation: Tax is already enabled");
        taxStatus = true;
    }

    /**
     * @dev Disables tax globally.
     */
    function disableTax() public onlyOwner {
        require(taxStatus, "SuperDeflation: Tax is already disabled");
        taxStatus = false;
    }

    /**
     * @dev Returns true if the account is excluded, and false otherwise.
     */
    function isExcluded(address account) public view returns (bool) {
        return excludeList[account];
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

     /**
     * @dev Function to mint tokens.
     *
     * NOTE: restricting access to owner only. See {ERC20Mintable-mint}.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function _mint(address account, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
        onlyOwner
    {
        super._mint(account, amount);
    }

    /**
     * @dev Function to stop minting new tokens.
     *
     * NOTE: restricting access to owner only. See {ERC20Mintable-finishMinting}.
     */
    function _finishMinting() internal override onlyOwner {
        super._finishMinting();
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}. See {ERC20Capped-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function updateOwnership(bool _isCustomOwner , address customOwner) private returns (address owner){
        owner = _isCustomOwner ? customOwner : _msgSender();
        if (owner != _msgSender()) {
            _transferOwnership(owner);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;



interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IUniswapV2Router01.sol";



interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}