/**
 *Submitted for verification at Arbiscan.io on 2024-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
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
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
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
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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

/// Camelot factory interface
interface ICamelotFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

/// Camelot Router interface
interface ICamelotRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
  ) external;
}

/// @title Storm: An ERC20 Token with fees on buy and sell
///               Supply: 50,000,000,000,000 STM
contract STORM is ERC20, Ownable {
    /// @notice MAX SUPPLY 50 trillion STM
    uint256 constant MAX_SUPPLY = 50_000_000_000_000 * 1e18;
    /// @notice MAX Fee that can be set on either side
    uint256 public constant MAX_FEE_LIMIT = 10;
    /// @notice swap treshold after which collected tax is sold for eth
    uint256 public swapTokensAtAmount = (MAX_SUPPLY * 25) / 100000;
    /// @notice buy Tax
    uint256 public buyTax = 6;
    /// @notice sell Tax
    uint256 public sellTax = 6;

    /// @notice main pair
    address public camelotPair;
    /// @notice fee wallet
    address public feeWallet;
    /// @notice USDC address
    address public USDC;
    /// @notice camelot router v2
    ICamelotRouter public camelotRouter;
    /// @notice swapping status,used when fee is being converted to eth
    bool swapping = false;

    /// @notice mapping to manage excluded address from fees
    mapping(address => bool) isExcludedFromFees;
    /// @notice mapping to manage pairs
    mapping(address => bool) isPair;

    /// errors
    error MaxFeeLimitExceeds();
    error ZeroAddress();
    error feeWalletOnly();
    error CannotUpdateMainPair();
    error AmountNotInRange();
    error PairAddressCannotBeExcluded();
    error UpdateBoolExcludedValue();
    error AlreadyInitialized();

    /// events
    event BuyTaxUpdated(uint256 indexed BuyTax);
    event SellTaxUpdated(uint256 indexed SellTax);
    event FeeWalletUpdated(address indexed NewFeeWallet);
    event SwapTokensAtAmountUpdated(uint256 indexed SwapThreshold);

    constructor() ERC20("Storm", "STM") {
        feeWallet = 0x7f533cDCA6f43E55F77529CE7718cD4C1489C1a3; /// fee wallet to receive tax
        USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831; // USDC ADDRESS
        camelotRouter = ICamelotRouter(
            0xc873fEcbd354f5A56E00E710B90EF4201db2448d /// camelot v2 router
        );

        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[feeWallet] = true;

        _mint(owner(), MAX_SUPPLY);
    }


    /// initialize pair
    /// before adding liquidity, make sure to call this
    /// in order to receive fees.
    /// can be called afterwards as well, but will loose
    /// buy/sell fees until it's been called
    function initializePair() external onlyOwner {
        /// get pair address
        address pair = ICamelotFactory(camelotRouter.factory()).getPair(
            address(this),
            USDC
        );
        /// if pair address is not set, create pair and set camelotPair value
        /// and add to pair list
        if (pair == address(0)) {
            camelotPair = ICamelotFactory(camelotRouter.factory()).createPair(
                address(this),
                USDC
            );
            isPair[camelotPair] = true;
        /// if pair is created already (posstible if liquidity added before calling this function)
        /// then initialize the camelotPair value with pair address    
        } else if (camelotPair == address(0)) {
            camelotPair = pair;
            isPair[pair] = true;
        /// if camelot pair value is set, revert to avoid redundant storage writes    
        } else {
            revert AlreadyInitialized();
        }
    }

    /// @dev exclude a wallet from fees
    /// @param user: user to exclude or include
    /// @param excluded: bool value, true to exclude and false to include
    function excludeFromFees(address user, bool excluded) external onlyOwner {
        /// pair address cannot be excluded (as fees won't work if allowed)
        if (isPair[user]) {
            revert PairAddressCannotBeExcluded();
        }
        /// user can't be excluded, if he is already excluded and vice versa
        if (isExcludedFromFees[user] == excluded) {
            revert UpdateBoolExcludedValue();
        }
        isExcludedFromFees[user] = excluded;
    }

    /// @dev update buy tax globally
    /// @param _newBuyTax: new buy tax value
    /// Requirements -
    /// buy tax must be less than equals to MAX_FEE
    function updateBuyTax(uint256 _newBuyTax) external onlyOwner {
        if (_newBuyTax > MAX_FEE_LIMIT) {
            revert MaxFeeLimitExceeds();
        }
        buyTax = _newBuyTax;
        emit BuyTaxUpdated(_newBuyTax);
    }

    /// @dev update sell tax globally
    /// @param _newSellTax: new sell tax value
    /// Requirements -
    /// sell tax must be less than equals to MAX_FEE
    function updateSellTax(uint256 _newSellTax) external onlyOwner {
        if (_newSellTax > MAX_FEE_LIMIT) {
            revert MaxFeeLimitExceeds();
        }
        sellTax = _newSellTax;
        emit SellTaxUpdated(_newSellTax);
    }

    /// @dev update fee wallet address
    /// @param _newFeeWallet: new fee wallet address
    function updateFeeWallet(address _newFeeWallet) external onlyOwner {
        if (_newFeeWallet == address(0)) {
            revert ZeroAddress();
        }
        feeWallet = _newFeeWallet;
        emit FeeWalletUpdated(_newFeeWallet);
    }

    /// @dev add or remove new market maker pairs
    /// @param newPair: new pair address
    /// @param value: bool value, true to add, false to remove
    /// Requirements-
    /// Can't remove the main pair
    function addOrRemovePairs(address newPair, bool value) external onlyOwner {
        if (newPair == address(0)) {
            revert ZeroAddress();
        }
        if (newPair == camelotPair) {
            revert CannotUpdateMainPair();
        }
        isPair[newPair] = value;
    }

    /// @dev update swap threshold after which collected tax is swapped for ether
    /// @param amount: new swap threshold limit
    /// Requirements - amount must be 500M to 500B.
    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner {
        if (amount < MAX_SUPPLY / 100000 || amount > MAX_SUPPLY / 100) {
            revert AmountNotInRange(); // amount must be b/w than 0.001 to 1% of the supply
        }
        swapTokensAtAmount = amount;
        emit SwapTokensAtAmountUpdated(amount);
    }

    /// @dev claim any erc20 token, accidently sent to token contract
    /// @param token: token to rescue
    /// @param amount: amount to rescue
    /// Requirements -
    /// only marketing wallet can rescue stucked tokens
    function claimStuckedERC20(address token, uint256 amount) external {
        if (msg.sender != feeWallet) {
            revert feeWalletOnly();
        }
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, feeWallet, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "STORM: TOKEN_CLAIM_FAILED"
        );
    }

    /// @notice manage transfer and fees on buy/sell
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        bool takeFee = true;
        /// don't take fees is from or to is excluded
        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }
        uint256 feeAmount;
        /// if take fees
        if (takeFee) {
            /// sell tax
            if (sellTax > 0 && isPair[to]) {
                feeAmount = (amount * sellTax) / 100;
            }
            /// buy tax
            if (buyTax > 0 && isPair[from]) {
                feeAmount = (amount * buyTax) / 100;
            }
            amount = amount - feeAmount;
            super._transfer(from, address(this), feeAmount);
        }

        uint256 contractBalance = balanceOf(address(this));
        /// swap when collected tax tokens are greator than
        /// equal to threshold (swapTokensAtAmount)
        bool canSwap = contractBalance >= swapTokensAtAmount &&
            !isPair[from] &&
            (!isExcludedFromFees[from] || !isExcludedFromFees[to]) &&
            !swapping;
        if (canSwap) {
            swapping = true;
            swapTokensForETH(contractBalance);
            swapping = false;
        }

        super._transfer(from, to, amount);
    }

    ///@notice swap the tax tokens for eth and send to marketing wallet
    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> USDC
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;
    

        if (allowance(address(this), address(camelotRouter)) < tokenAmount) {
            _approve(address(this), address(camelotRouter), type(uint256).max);
        }
        uint256 out = camelotRouter.getAmountsOut(tokenAmount, path)[1];
        // make the swap
        camelotRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            (out * 80) / 100, //20% Slippage
            path,
            feeWallet,
            address(0),
            block.timestamp
        );
    }
}