/**
 *Submitted for verification at Arbiscan on 2023-05-22
*/

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;



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

// File: StageMarketCap Project/Main Project/STMC_Token.sol



pragma solidity 0.8.19;




contract STMC_Token is ERC20, ERC20Burnable, Ownable {

    uint256 private immutable tokenTotalSupply = 100_000_000e18;

    error DoNotSendFundsDirectlyToTheContract();

    constructor() ERC20("StageMarketCap", "STMC") {        
        _mint(owner(), tokenTotalSupply);
    }

    receive() external payable {
        revert DoNotSendFundsDirectlyToTheContract();
    }     
}



// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
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

// File: StageMarketCap Project/Main Project/STMC_ICO_Rev09.sol



pragma solidity 0.8.19;




/**
 * @title STMC_ICO Contract
 * @dev A smart contract that implements the STMC initial coin offering (ICO),
 * allowing investors to purchase STMC tokens in exchange for ether.
 */
contract STMC_ICO is Ownable, ReentrancyGuard {             
    
    // Stores the STMC_Token contract instance. 
    STMC_Token private immutable _token = 
        STMC_Token(payable(0x78523725F470Fd45825F014b52fe07f8417aFB22));

    // Stores the maximum number of tokens that can be purchased in a single transaction.
    uint256 private immutable _maxTokensPerTx = 100_000e18;

    // Stores the minimum number of tokens that can be purchased in a single transaction.
    uint256 private immutable _minTokensPerTx = 10e18;

    // Stores the maximum number of tokens that a buyer can hold.
    uint256 private immutable _maxTokensPerBuyer = 1_000_000e18;

    // Stores the Chainlink price feed for native coin of the chain to USD. (ETH/USD, MATIC/USD,...)
    AggregatorV3Interface private toUsdPriceFeed;

    // Stores the USTD address according to the chain.
    IERC20 private _usdt;   

    // Stores the rate of USD per token. (1 STMC = 0.01$ & after the first week 1 STMC = 0.03$)
    uint256 private _usdRatePerToken;    
    
    // Stores the total amount of funds raised in the ICO.
    uint256 private _fundsRaised;     

    // Stores the total amount of tokens available for sale in the ICO.
    uint256 private _icoTokenAmount;    

    // Stores the Unix timestamp for the start of the ICO.
    uint256 private _icoOpeningTime;

    // Stores the Unix timestamp for the end of the ICO.
    uint256 private _icoClosingTime; 

    // Stores the duration of the ICO in seconds.
    uint256 private _icoDurationInSeconds;     

    // Maps the token balance of each buyer to their address.    
    mapping(address => uint256) private tokenAmountInWallet;

    // An error message that is thrown if funds are sent directly to the contract without a function call.
    error DoNotSendFundsDirectlyToTheContract();  

    error IcoShouldBeClosed();
    error IcoShouldBeOpened();
    error InvalidAddress();
    error InvalidAmount();
    error InvalidDuration();    
    error notEnoughFunds();
    error NoTokensToBurn();    
    error NoTokensToBuy();
    error NotEnoughTokensToBuy();
    error InvalidPayment();    
    error HigherThanMaxAmount();
    error LowerThanMinAmount();
    error HighrThanMaxHolding();

    event TokensDeposited(address indexed _owner, uint256 amount);
    event FundsWithdrawn(address indexed _owner, uint256 _amount);
    event TokensPurchased(address indexed beneficiary, uint256 value, uint256 amount);
    event usdtWithdrawn(address indexed _owner, uint256 _amount);
    event TokensBurned(uint256 amount);

    constructor() {
        _setPriceFeedByChainId();
        _setUSDTaddress(); 
    }

    /**
    * @dev The contract's fallback function that does not allow direct payments to the contract.
    * @notice Prevents users from sending ether directly to the contract by reverting the transaction.
    */
    receive() external payable {
        revert DoNotSendFundsDirectlyToTheContract();
    }

    /**
    * @dev Modifier to restrict certain functions to the time when the ICO is closed.
    * @notice This modifier should be used in conjunction with isOpen() function.
    */
    modifier onlyWhileClosed {
         //require(!isOpen(), "ICO Should be closed");
         if (isOpen()) revert IcoShouldBeClosed(); 
        _;
    }    

    /**
    * @dev Modifier to restrict certain functions to the time when the ICO is open.
    * @notice This modifier should be used in conjunction with isOpen() function.
    */
    modifier onlyWhileOpen {
        //require(isOpen(), "ICO: has been already closed");
        if (!isOpen()) revert IcoShouldBeOpened();
        _;
    }

    /**
    * @dev Modifier to change _usdRatePerToken to 33 when one week passes from the ICO start time.
    */
    modifier checkTokenRate {
        if (block.timestamp >= (_icoOpeningTime + 7 days)) 
            _usdRatePerToken = 0.03 * 1e18;
            _;
    }

    /**
    * @dev Checks if the ICO is currently open.
    * @return A boolean indicating whether the ICO is currently open or not.
    */
    function isOpen() public view returns (bool) {        
        return block.timestamp >= _icoOpeningTime && block.timestamp <= _icoClosingTime;
    }   

    /**
    * @dev Sets the price feed address of the native coin to USD from the Chainlink oracle.
    * @param _toUsdPricefeed The address of native coin to USD price feed.
    */    
    function setPriceFeed(address _toUsdPricefeed) external onlyOwner onlyWhileClosed {
        //require(_toUsdPricefeed != address(0), "ICO: Price feed address cannot be zero" );
        if ((_toUsdPricefeed == address(0)) || (_toUsdPricefeed == address(_token))) revert InvalidAddress();
        toUsdPriceFeed = AggregatorV3Interface(_toUsdPricefeed);        
    }

    /**
    * @dev Sets the address of the USD stable coin.
    * @param _stableCoin The address of native USD stable coin.
    */    
    function setStableCoin(address _stableCoin) external onlyOwner onlyWhileClosed {
        //require(_stableCoin != address(0), "ICO: Price feed address cannot be zero" );
        if ((_stableCoin == address(0)) || (_stableCoin == address(_token))) revert InvalidAddress();
        _usdt = IERC20(_stableCoin);        
    }    
    
    /**
    * @dev Deposits tokens into the ICO contract.
    * @notice Only the contract owner can deposit tokens.
    * @param _amount The amount of tokens to be deposited.
    */
    function depositTokens(uint _amount) external onlyOwner returns (bool) {        
        //require(_amount > 0, "ICO: Invalid token amount");
        if (_amount <= 0) revert InvalidAmount();
        //require((_icoTokenAmount + _amount) <= 10_000_000e18, "ICO: Cannot Deposit more than 10 milion tokens");
        if (_icoTokenAmount + _amount > 10_000_000e18) revert HigherThanMaxAmount();
        _icoTokenAmount += _amount;      
        _token.transferFrom(owner(), address(this), _amount);

        emit TokensDeposited(owner(), _amount);
        return true;      
    }
    
    /**
    * @dev Withdraws all funds from the ICO contract.
    * @notice Only the contract owner can withdraw funds.
    * @notice This function can only be called while the ICO is closed.
    * @return _success boolean indicating whether the withdrawal was successful.
    */
    function withdrawFunds(uint _value) external onlyOwner onlyWhileClosed returns (bool _success) {        
        //require(_value > 0, "ICO: cannot withdraw zero funds");
        if (_value <= 0) revert InvalidAmount();
        //require(_fundsRaised >= _value, "ICO: No Funds to Withdraw");
        if (_fundsRaised < _value) revert notEnoughFunds();
        
        _fundsRaised -= _value;

        (_success,) = owner().call{value: _value}("");
        emit FundsWithdrawn(owner(), _value);
        return _success;        
    }

    /**
    * @dev Withdraws Stable Coins from the ICO contract.
    * @notice Only the contract owner can withdraw tokens.    
    * @param _amount The amount of tokens to be withdrawn.
    */
    function withdrawUSDT(uint _amount) external onlyOwner onlyWhileClosed returns (bool) {        
                
        if (_amount <= 0) revert InvalidAmount();       
                
        if (_usdt.balanceOf(address(this)) < _amount) revert notEnoughFunds();        

        _usdt.transfer(owner(), _amount);
        
        emit usdtWithdrawn(owner(), _amount);
        return true; 
    }

    /**
    * @dev burns the remained tokens (if any) in ICO.
    * @notice This function can only be called while the ICO is closed.
    */
    function burnRemainedTokens() external onlyOwner onlyWhileClosed returns (bool) {
        //require(_icoTokenAmount != 0, "ICO: No Tokens to Burn");
        if (_icoTokenAmount == 0) revert NoTokensToBurn();
        uint256 remainedAmount = _icoTokenAmount;
        _icoTokenAmount = 0;
        _token.burn(remainedAmount);

        emit TokensBurned(remainedAmount);
        return true;        
    }
    
    /**
    * @dev Opens the ICO for buying tokens.
    * @param _icoDurationInDays The duration of the ICO in days.
    * @notice Only the contract owner can open the ICO.
    */
    function openIco(uint256 _icoDurationInDays) external onlyOwner {
        //require(_icoDurationInDays > 0, "ICO: Invalid ico Duration");
        if (_icoDurationInDays <= 0) revert InvalidDuration();        
        //require(!isOpen(), "ICO: has been already opened");
        if (isOpen()) revert IcoShouldBeClosed();        
        //require(_icoTokenAmount > 0, "ICO: No tokens to buy");
        if (_icoTokenAmount == 0) revert NoTokensToBuy();
                
        _usdRatePerToken = 0.01 * 1e18;
        _icoOpeningTime = block.timestamp;
        _icoDurationInSeconds = _icoDurationInDays * 86400;
        _icoClosingTime = _icoOpeningTime + _icoDurationInSeconds;                                 
    }

    /**
    * @dev Sets the NativeCoin/USD price feed address based on the chain ID.    
    */
    function _setPriceFeedByChainId() private {
        uint256 id;
        assembly {
            id := chainid()
        }
        
        // Arbitrum Chain ---> ETH/USD
        if (id == 42161) toUsdPriceFeed = AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);

        // BNB Chain ---> BNB/USD
        else if (id == 56) toUsdPriceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

        // Polygon Chain ---> MATIC/USD
        else if (id == 137) toUsdPriceFeed = AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);

        // Fantom Chain ---> FTM/USD
        else if (id == 250) toUsdPriceFeed = AggregatorV3Interface(0xf4766552D15AE4d256Ad41B6cf2933482B0680dc);

        // Avalnche Chain ---> AVAX/USD
        else if (id == 43114) toUsdPriceFeed = AggregatorV3Interface(0x0A77230d17318075983913bC2145DB16C7366156);
    }

    /**
    * @dev Sets the NativeCoin/USD price feed contract based on the chain ID.    
    */
    function _setUSDTaddress() private {
        uint256 id;
        assembly {
            id := chainid()
        }
        
        // Arbitrum Chain 
        if (id == 42161) _usdt = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);

        // BNB Chain 
        else if (id == 56) _usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);

        // Polygon Chain 
        else if (id == 137) _usdt = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);

        // Fantom Chain 
        else if (id == 250) _usdt = IERC20(0x049d68029688eAbF473097a2fC38ef61633A3C7A);

        // Avalnche Chain 
        else if (id == 43114) _usdt = IERC20(0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7);
    }

    /**
    * @dev Extends the ICO closing time.
    * @notice Only the contract owner can extend the ICO.
    * @notice This function can only be called while the ICO is open.
    * @param _addedDurationInDays The added ICO duration in days.
    */
    function extendIcoTime(uint256 _addedDurationInDays) external onlyOwner onlyWhileOpen {
        //require(_addedDurationInDays > 0, "ICO: Invalid Duration");
        if (_addedDurationInDays <= 0) revert InvalidDuration();                
         _icoDurationInSeconds += _addedDurationInDays * 86400;      
        _icoClosingTime = _icoOpeningTime + _icoDurationInSeconds;
    }

    /**
    * @dev Closes the ICO for buying tokens.
    * @notice Only the contract owner can close the ICO.
    * @notice This function can only be called while the ICO is open.
    */
    function closeIco() external onlyOwner onlyWhileOpen {        
        _icoOpeningTime = 0;
        _icoClosingTime = 0;
        _icoDurationInSeconds = 0;                 
    }  
    

    /**
    * @dev Allows users to buy tokens during the ICO.
    * @notice This function can only be called while the ICO is open.    
    * @return A boolean indicating whether the token purchase was successful.
    */
    function buyTokens() external onlyWhileOpen nonReentrant payable returns(bool) {        
        address beneficiary = msg.sender;
        uint256 paymentInWei = msg.value;                

        _preValidatePurchase(beneficiary, paymentInWei);

        uint256 tokenAmount = _getTokenAmount(false, paymentInWei);       

        _processPurchase(beneficiary, tokenAmount);

        _fundsRaised += paymentInWei;
        tokenAmountInWallet[beneficiary] += tokenAmount;        
        _icoTokenAmount -= tokenAmount;

        _token.transfer(beneficiary, tokenAmount);

        emit TokensPurchased(beneficiary, paymentInWei, tokenAmount);
        return true;
    }

    /**
    * @dev Allows users to buy tokens with a Stable coin during the ICO.
    * @notice This function can only be called while the ICO is open.    
    * @param _usdtAmount The amount of USDT in wei.    
    * @return A boolean indicating whether the token purchase was successful.
    */
    function buyWithUSDT(uint256 _usdtAmount) external onlyWhileOpen nonReentrant returns(bool) {    

        address beneficiary = msg.sender;                                     

        _preValidatePurchase(beneficiary, _usdtAmount);
        
        uint256 tokenAmount = _getTokenAmount(true, _usdtAmount);      

        _processPurchase(beneficiary, tokenAmount);

        tokenAmountInWallet[beneficiary] += tokenAmount;        
        _icoTokenAmount -= tokenAmount;

        _usdt.transferFrom(beneficiary, address(this), _usdtAmount);
        _token.transfer(beneficiary, tokenAmount);

        emit TokensPurchased(beneficiary, _usdtAmount, tokenAmount);       

        return true;
    }    

    /**
    * @dev Validates that a token purchase is valid.
    * @notice This function is called by the `buyTokens()` function to validate the transaction.
    * @param _beneficiary The address of the beneficiary of the token purchase.
    * @param _amount The amount of Ether/USDT sent in the transaction.
    */
    function _preValidatePurchase(address _beneficiary, uint256 _amount) private view {
        //require(beneficiary != address(0), "ICO: Beneficiary address cannot be zero");
        if (_beneficiary == address(0)) revert InvalidAddress();
        //require(paymentInWei != 0, "ICO: Payment is zero");
        if (_amount <= 0) revert InvalidPayment();
        //require(_icoTokenAmount !=0, "ICO: No tokens to buy"); 
        if (_icoTokenAmount ==0) revert NoTokensToBuy();      
    }

    /**
    * @dev Processes a token purchase for a given beneficiary.
    * @notice This function is called by the `buyTokens()` function to process a token purchase.
    * @param _beneficiary The address of the beneficiary of the token purchase.
    * @param _tokenAmount The amount of tokens to be purchased.
    */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) private view {        
        //require(_tokenAmount <= _icoTokenAmount, "ICO: not enough tokens to buy");
        if (_tokenAmount > _icoTokenAmount) revert NotEnoughTokensToBuy();
        //require(_tokenAmount >= _minTokensPerTx, "ICO: cannot buy less than the max amount" );
        if (_tokenAmount < _minTokensPerTx) revert LowerThanMinAmount();
        //require(_tokenAmount <= _maxTokensPerTx, "ICO: cannot buy more than the max amount" );
        if (_tokenAmount > _maxTokensPerTx) revert HigherThanMaxAmount();
        //require(tokenAmountInWallet[_beneficiary] + _tokenAmount <= _maxTokensPerBuyer, "ICO: Cannot hold more tokens than max allowed");
        if (tokenAmountInWallet[_beneficiary] + _tokenAmount > _maxTokensPerBuyer) revert HighrThanMaxHolding();         
    }
    
    /**
    * @dev Calculates the amount of tokens that can be purchased with the specified amount of ether, based on the current token rate in USD.
    * @param paymentInWei The amount of ether sent to purchase tokens.
    * @return The number of tokens that can be purchased with the specified amount of ether.
    */
    function _getTokenAmount(bool isUSDT, uint256 paymentInWei) private checkTokenRate returns (uint256) {       
        uint priceInwei;

        if (isUSDT) {
            priceInwei = 1e18;
        }  
        else {            
            priceInwei = _priceInWei();
        }         
        
        return ((paymentInWei * priceInwei) / _usdRatePerToken);
    }   

    /**
    * @dev Gets the latest NativeCoin/USD price from the Chainlink oracle and returns the price in Wei.
    * @return The price of 1 Native Coin in Wei.
    */
    function _priceInWei() private view returns (uint256) {
        (,int price,,,) = toUsdPriceFeed.latestRoundData();
        uint8 priceFeedDecimals = toUsdPriceFeed.decimals();
        price = _toWei(price, priceFeedDecimals, 18);
        return uint256(price);
    } 
    
    /**
    * @dev Converts the price from the Chainlink Oracle to the appropriate data type before performing arithmetic operations.
    * @param _amount The price returned from the Chainlink Oracle.
    * @param _amountDecimals The number of decimals in the price returned from the Chainlink Oracle.
    * @param _chainDecimals The number of decimals used by the Ethereum blockchain (18 for ether).
    * @return The price converted to the appropriate data type.
    */
    function _toWei(int256 _amount, uint8 _amountDecimals, uint8 _chainDecimals) private pure returns (int256) {        
        if (_chainDecimals > _amountDecimals)
            return _amount * int256(10 **(_chainDecimals - _amountDecimals));
        else
            return _amount * int256(10 **(_amountDecimals - _chainDecimals));
    }

    /**
    * @dev Returns the total amount of funds raised in the ICO.
    * @return The total amount of funds raised in the ICO.
    */
    function getIcoFundsBalance() external view returns(uint256) {
        return _fundsRaised;
    } 

    /**
    * @dev Returns the total amount of ICO tokens remaining.
    * @return The total amount of ICO tokens remaining.
    */
    function getIcoSTMCtokensBalance() external view returns(uint256) {
        return _icoTokenAmount;
    }

    /**
    * @dev Returns the total amount of USDT raised in the ICO.
    * @return The total amount of USDT raised in the ICO.
    */
    function getIcoUsdtBalance() external view returns(uint256) {
        return _usdt.balanceOf(address(this));
    }

    /**
    * @dev Returns the number of tokens held by the specified beneficiary.
    * @param _beneficiary The address of the beneficiary.
    * @return The number of tokens held by the specified beneficiary.
    */
    function getTokenBuyerBalance(address _beneficiary) external view returns(uint256) {
        return tokenAmountInWallet[_beneficiary];
    }

    /**
    * @dev Returns the maximum number of tokens that can be purchased in a single transaction.
    */
    function getMaxTokensPerTx() external pure returns(uint256) {
        return _maxTokensPerTx;
    }

    /**
    * @dev Returns the minimum number of tokens that can be purchased in a single transaction.
    */
    function getMinTokensPerTx() external pure returns(uint256) {
        return _minTokensPerTx;
    }

    /**
    * @dev Returns the maximum number of tokens that a buyer can hold.
    */
    function getMaxTokensPerBuyer() external pure returns(uint256) {
        return _maxTokensPerBuyer;
    }

    /**
    * @dev Returns the duration of the ICO in seconds.
    */    
    function getIcoDurationInSeconds() external view returns(uint256) {
        return _icoDurationInSeconds;
    }

    /**
    * @dev Returns the Unix timestamp for the start of the ICO.
    */    
    function getIcoOpeningTime() external view returns(uint256) {
        return _icoOpeningTime;
    }

    /**
    * @dev Returns the Unix timestamp for the end of the ICO.
    */    
    function getIcoClosingTime() external view returns(uint256) {
        return _icoClosingTime;
    }

    /**  
    * @dev Returns the rate of USD per token.
    * @notice 1 STMC = 0.01$ & after the first week 1 STMC = 0.03$
    */    
    function getUsdRatePerToken() external view returns(uint256) {
        return _usdRatePerToken;
    }

    /**
    * @dev Returns the price feed address and the price of the native coin to USD from the Chainlink oracle.    
    */  
    function getPriceFeedData() external view returns(address, uint256) {
        return (address(toUsdPriceFeed), _priceInWei());
    }

    /**
    * @dev Returns the address of USDT according to the chain.    
    */
    function getUSDTaddress() external view returns(address) {
        return address(_usdt);
    }

    function getSTMCtokenAddress() external view returns(address) {
        return address(_token);
    }     
    
}

/*

USDT address:

Mainnets:

Arbitrum:       0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9      id = 42161
BSC:            0x55d398326f99059ff775485246999027b3197955      id = 56
Polygon:        0xc2132d05d31c914a87c6611c10748aeb04b58e8f      id = 137
Fantom:         0x049d68029688eAbF473097a2fC38ef61633A3C7A      id = 250
Avalanche:      0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7      id = 43114




/*
Price Feeds list:
https://docs.chain.link/data-feeds/price-feeds/addresses

Mainnets:

Arbitrum:       0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612      id = 42161
BSC:            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE      id = 56
Polygon:        0xAB594600376Ec9fD91F8e885dADF0CE036862dE0      id = 137
Fantom:         0xf4766552D15AE4d256Ad41B6cf2933482B0680dc      id = 250
Avalanche:      0x0A77230d17318075983913bC2145DB16C7366156      id = 43114

--------------------------------------

Testnets:

Arbitrum:       0x62CAe0FA2da220f43a51F86Db2EDb36DcA9A5A08      id = 421613
BSC:            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526      id = 97
Polygon:        0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada      id = 80001
Fantom:         0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D      id = 4002
Avalanche:      0x5498BB86BC934c8D34FDA08E81D444153d0D06aD      id = 43113

*/