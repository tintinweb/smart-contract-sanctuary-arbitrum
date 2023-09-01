/**
 *Submitted for verification at Arbiscan.io on 2023-08-30
*/

// SPDX-License-Identifier: MIT
//
// BOLT SWAP
//
// Multichain AMM Protocol with low fees and LP Mining 
//
//
// Website: https://boltswap.xyz
// Telegram: https://t.me/boltswapfi
// Twitter: https://twitter.com/BoltSwapFi
//

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

pragma solidity ^0.8.0;

interface IWCANTO {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

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

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;


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

pragma solidity ^0.8.0;

interface IFeeDiscountOracle {
    function buyFeeDiscountFor(address account, uint256 totalFeeAmount)
        external
        view
        returns (uint256 discountAmount);

    function sellFeeDiscountFor(address account, uint256 totalFeeAmount)
        external
        view
        returns (uint256 discountAmount);
}

pragma solidity ^0.8.0;

interface IBoltSwapV2Pair {
    function factory() external view returns (address);

    function fees() external view returns (address);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function mint(address to) external returns (uint256 liquidity);

    function getReserves()
        external
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        );

    function getAmountOut(uint256, address) external view returns (uint256);

    function current(address tokenIn, uint256 amountIn)
        external
        view
        returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function stable() external view returns (bool);

    function balanceOf(address) external view returns (uint256);

    //LP token pricing
    function sample(
        address tokenIn,
        uint256 amountIn,
        uint256 points,
        uint256 window
    ) external view returns (uint256[] memory);

    function quote(
        address tokenIn,
        uint256 amountIn,
        uint256 granularity
    ) external view returns (uint256);

    function claimFeesFor(address account)
        external
        returns (uint256 claimed0, uint256 claimed1);

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);

    function claimableFeesFor(address account)
        external
        returns (uint256 claimed0, uint256 claimed1);

    function claimableFees()
        external
        returns (uint256 claimed0, uint256 claimed1);
}

pragma solidity ^0.8.0;

interface IBoltSwapV2Factory {
    function allPairsLength() external view returns (uint256);

    function isPair(address pair) external view returns (bool);

    function pairCodeHash() external pure returns (bytes32);

    function getPair(
        address tokenA,
        address token,
        bool stable
    ) external view returns (address);

    function createPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external returns (address);

    function createPair(address tokenA, address tokenB)
        external
        returns (address);

    function getInitializable()
        external
        view
        returns (
            address token0,
            address token1,
            bool stable
        );

    function protocolFeesShare() external view returns (uint256);

    function protocolFeesRecipient() external view returns (address);

    function tradingFees(address pair, address to)
        external
        view
        returns (uint256);

    function isPaused() external view returns (bool);
}

pragma solidity ^0.8.0;


interface IBoltSwapV2Router01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function wcanto() external view returns (IWCANTO);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountCANTOMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountCANTO);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amount);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function pairFor(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

pragma solidity ^0.8.0;

interface ILiquidityManageable {
    function setLiquidityManagementPhase(bool _isManagingLiquidity) external;

    function isLiquidityManager(address _addr) external returns (bool);

    function isLiquidityManagementPhase() external returns (bool);
}

pragma solidity =0.8.17;


contract BoltSwapToken is ERC20, Ownable, ILiquidityManageable {
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant FEE_DENOMINATOR = 1e4;
    uint256 public constant MAX_FEE = 1000;

    uint256 public burnBuyFee;
    uint256 public farmsBuyFee;
    uint256 public stakingBuyFee;
    uint256 public treasuryBuyFee;
    uint256 public totalBuyFee;

    uint256 public burnSellFee;
    uint256 public farmsSellFee;
    uint256 public stakingSellFee;
    uint256 public treasurySellFee;
    uint256 public totalSellFee;

    address public farmsFeeRecipient;
    address public stakingFeeRecipient;
    address public treasuryFeeRecipient;

    bool public tradingEnabled;
    uint256 public tradingEnabledTimestamp = 0; // 0 means trading is not active

    IBoltSwapV2Router01 public swapFeesRouter;
    IFeeDiscountOracle public feeDiscountOracle;
    address public swapPairToken;
    bool public swappingFeesEnabled;
    bool public isSwappingFees;
    uint256 public swapFeesAtAmount;
    uint256 public maxSwapFeesAmount;
    uint256 public maxWalletAmount;

    uint256 public sniperBuyBaseFee = 0;
    uint256 public sniperBuyFeeDecayPeriod = 0;
    uint256 public sniperBuyFeeBurnShare = 2500;
    bool public sniperBuyFeeEnabled = true;

    uint256 public sniperSellBaseFee = 0;
    uint256 public sniperSellFeeDecayPeriod = 0;
    uint256 public sniperSellFeeBurnShare = 2500;
    bool public sniperSellFeeEnabled = true;

    bool public pairAutoDetectionEnabled;
    bool public indirectSwapFeeEnabled;
    bool public maxWalletEnabled;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isLiquidityManager;
    mapping(address => bool) public isWhitelistedFactory;
    mapping(address => bool) public isBot;

    bool internal _isLiquidityManagementPhase;
    uint256 internal _currentCacheVersion;
    mapping(address => bool) internal _isBoltPair;
    mapping(uint256 => mapping(address => bool))
        internal _isCachedAutodetectedBoltPair;
    mapping(address => bool) internal _isExcludedFromMaxWallet;

    event BuyFeeUpdated(uint256 _fee, uint256 _previousFee);
    event SellFeeUpdated(uint256 _fee, uint256 _previousFee);
    event BoltPairAdded(address _pair);
    event BoltPairRemoved(address _pair);
    event AddressExcludedFromFees(address _address);
    event AddressIncludedInFees(address _address);
    event WhitelistedFactoryAdded(address _factory);
    event WhitelistedFactoryRemoved(address _factory);

    error TradingNotEnabled();
    error TradingAlreadyEnabled();
    error SniperBotDetected();
    error MaxWalletReached();
    error TimestampIsInThePast();
    error FeeTooHigh();
    error InvalidFeeRecipient();
    error NotLiquidityManager();
    error TransferFailed();
    error ArrayLengthMismatch();

    constructor(
        address _router,
        address _swapPairToken
    ) ERC20("BoltSwap", "BOLT") {
        IBoltSwapV2Router01 router = IBoltSwapV2Router01(_router);
        IBoltSwapV2Factory factory = IBoltSwapV2Factory(router.factory());
        swapPairToken = _swapPairToken;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[DEAD] = true;

        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[address(this)] = true;
        _isExcludedFromMaxWallet[DEAD] = true;

        burnBuyFee = 0;
        farmsBuyFee = 0;
        stakingBuyFee = 0;
        treasuryBuyFee = 0;
        setBuyFees(burnBuyFee, farmsBuyFee, stakingBuyFee, treasuryBuyFee);

        burnSellFee = 0;
        farmsSellFee = 150;
        stakingSellFee = 100;
        treasurySellFee = 50;
        setSellFees(burnSellFee, farmsSellFee, stakingSellFee, treasurySellFee);

        farmsFeeRecipient = owner();
        stakingFeeRecipient = owner();
        treasuryFeeRecipient = owner();

        isLiquidityManager[address(router)] = true;
        isWhitelistedFactory[address(factory)] = true;

        address pair = factory.createPair(address(this), swapPairToken);
        address feesVault = IBoltSwapV2Pair(pair).fees();
        _isExcludedFromMaxWallet[feesVault] = true;
        isExcludedFromFee[feesVault] = true;
        _isBoltPair[pair] = true;
        maxWalletEnabled = true;
        // pairAutoDetectionEnabled = true;

        _mint(owner(), 1337000 * 10 ** decimals());

        swapFeesRouter = router;
        swapFeesAtAmount = (totalSupply() * 3) / 1e5;
        maxSwapFeesAmount = (totalSupply() * 4) / 1e5;
        maxWalletAmount = (totalSupply() * 1) / 1e3; // 1% of the CIRCULATING supply
    }

    modifier onlyLiquidityManager() {
        if (!isLiquidityManager[msg.sender]) {
            revert NotLiquidityManager();
        }
        _;
    }

    /************************************************************************/

    function isBoltPair(address _pair) public returns (bool isPair) {
        if (_isBoltPair[_pair]) {
            return true;
        }

        if (!pairAutoDetectionEnabled) {
            return false;
        }

        if (_isCachedAutodetectedBoltPair[_currentCacheVersion][_pair]) {
            return true;
        }

        if (_pair.code.length == 0) {
            return false;
        }

        (bool success, bytes memory data) = _pair.staticcall(
            abi.encodeWithSignature("factory()")
        );
        if (!success) return false;
        address factory = abi.decode(data, (address));
        if (factory == address(0)) return false;

        bool isVerifiedPair = isWhitelistedFactory[factory] &&
            IBoltSwapV2Factory(factory).isPair(_pair);

        (success, data) = _pair.staticcall(abi.encodeWithSignature("token0()"));
        if (!success) return false;
        address token0 = abi.decode(data, (address));
        if (token0 == address(this)) {
            if (isVerifiedPair) {
                _isCachedAutodetectedBoltPair[_currentCacheVersion][
                    _pair
                ] = true;
            }

            return true;
        }

        (success, data) = _pair.staticcall(abi.encodeWithSignature("token1()"));
        if (!success) return false;
        address token1 = abi.decode(data, (address));
        if (token1 == address(this)) {
            if (isVerifiedPair) {
                _isCachedAutodetectedBoltPair[_currentCacheVersion][
                    _pair
                ] = true;
            }

            return true;
        }

        return false;
    }

    function _shouldTakeTransferTax(
        address sender,
        address recipient
    ) internal returns (bool) {
        if (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
            return false;
        }

        return
            !_isLiquidityManagementPhase &&
            (isBoltPair(sender) || isBoltPair(recipient));
    }

    function sniperBuyFee() public view returns (uint256) {
        if (!sniperBuyFeeEnabled) {
            return 0;
        }

        uint256 timeSinceLaunch = block.timestamp - tradingEnabledTimestamp;

        if (timeSinceLaunch >= sniperBuyFeeDecayPeriod) {
            return 0;
        }

        return
            sniperBuyBaseFee -
            (sniperBuyBaseFee * timeSinceLaunch) /
            sniperBuyFeeDecayPeriod;
    }

    function sniperSellFee() public view returns (uint256) {
        if (!sniperSellFeeEnabled) {
            return 0;
        }

        uint256 timeSinceLaunch = block.timestamp - tradingEnabledTimestamp;

        if (timeSinceLaunch >= sniperSellFeeDecayPeriod) {
            return 0;
        }

        return
            sniperSellBaseFee -
            (sniperSellBaseFee * timeSinceLaunch) /
            sniperSellFeeDecayPeriod;
    }

    /************************************************************************/

    function buyFeeDiscountFor(
        address account,
        uint256 totalFeeAmount
    ) public view returns (uint256) {
        if (address(feeDiscountOracle) == address(0)) return 0;
        return feeDiscountOracle.buyFeeDiscountFor(account, totalFeeAmount);
    }

    function sellFeeDiscountFor(
        address account,
        uint256 totalFeeAmount
    ) public view returns (uint256) {
        if (address(feeDiscountOracle) == address(0)) return 0;
        return feeDiscountOracle.sellFeeDiscountFor(account, totalFeeAmount);
    }

    function _takeBuyFee(
        address sender,
        address user,
        uint256 amount
    ) internal returns (uint256) {
        if (totalBuyFee == 0) return 0;

        uint256 totalFeeAmount = (amount * totalBuyFee) / FEE_DENOMINATOR;
        uint256 feeDiscountAmount = buyFeeDiscountFor(user, totalFeeAmount);

        totalFeeAmount -= feeDiscountAmount;
        if (totalFeeAmount == 0) return 0;

        uint256 burnFeeAmount = (totalFeeAmount * burnBuyFee) / totalBuyFee;
        uint256 farmsFeeAmount = (totalFeeAmount * farmsBuyFee) / totalBuyFee;
        uint256 stakingFeeAmount = (totalFeeAmount * stakingBuyFee) /
            totalBuyFee;
        uint256 treasuryFeeAmount = totalFeeAmount -
            burnFeeAmount -
            farmsFeeAmount -
            stakingFeeAmount;

        if (burnFeeAmount > 0) super._transfer(sender, DEAD, burnFeeAmount);

        if (farmsFeeAmount > 0)
            super._transfer(sender, farmsFeeRecipient, farmsFeeAmount);

        if (stakingFeeAmount > 0)
            super._transfer(sender, stakingFeeRecipient, stakingFeeAmount);

        if (treasuryFeeAmount > 0)
            super._transfer(sender, address(this), treasuryFeeAmount);

        return totalFeeAmount;
    }

    function _takeSellFee(
        address sender,
        address user,
        uint256 amount
    ) internal returns (uint256) {
        if (totalSellFee == 0) return 0;

        uint256 totalFeeAmount = (amount * totalSellFee) / FEE_DENOMINATOR;
        uint256 feeDiscountAmount = sellFeeDiscountFor(user, totalFeeAmount);

        totalFeeAmount -= feeDiscountAmount;
        if (totalFeeAmount == 0) return 0;

        uint256 burnFeeAmount = (totalFeeAmount * burnSellFee) / totalSellFee;
        uint256 farmsFeeAmount = (totalFeeAmount * farmsSellFee) / totalSellFee;
        uint256 stakingFeeAmount = (totalFeeAmount * stakingSellFee) /
            totalSellFee;
        uint256 treasuryFeeAmount = totalFeeAmount -
            burnFeeAmount -
            farmsFeeAmount -
            stakingFeeAmount;

        if (burnFeeAmount > 0) super._transfer(sender, DEAD, burnFeeAmount);

        if (farmsFeeAmount > 0)
            super._transfer(sender, farmsFeeRecipient, farmsFeeAmount);

        if (stakingFeeAmount > 0)
            super._transfer(sender, stakingFeeRecipient, stakingFeeAmount);

        if (treasuryFeeAmount > 0)
            super._transfer(sender, address(this), treasuryFeeAmount);

        return totalFeeAmount;
    }

    function _takeSniperBuyFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        uint256 totalFeeAmount = (amount * sniperBuyFee()) / FEE_DENOMINATOR;
        uint256 burnFeeAmount = (totalFeeAmount * sniperBuyFeeBurnShare) /
            FEE_DENOMINATOR;
        uint256 treasuryFeeAmount = totalFeeAmount - burnFeeAmount;

        if (burnFeeAmount > 0) super._transfer(sender, DEAD, burnFeeAmount);

        if (treasuryFeeAmount > 0)
            super._transfer(sender, address(this), treasuryFeeAmount);

        return totalFeeAmount;
    }

    function _takeSniperSellFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        uint256 totalFeeAmount = (amount * sniperSellFee()) / FEE_DENOMINATOR;
        uint256 burnFeeAmount = (totalFeeAmount * sniperSellFeeBurnShare) /
            FEE_DENOMINATOR;
        uint256 treasuryFeeAmount = totalFeeAmount - burnFeeAmount;

        if (burnFeeAmount > 0) super._transfer(sender, DEAD, burnFeeAmount);

        if (treasuryFeeAmount > 0)
            super._transfer(sender, address(this), treasuryFeeAmount);

        return totalFeeAmount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (
            !(tradingEnabled && tradingEnabledTimestamp <= block.timestamp) &&
            !isExcludedFromFee[sender] &&
            !isExcludedFromFee[recipient]
        ) {
            revert TradingNotEnabled();
        }

        if (isBot[sender] || isBot[recipient]) revert SniperBotDetected();

        if (
            maxWalletEnabled &&
            !isExcludedFromMaxWallet(recipient) &&
            balanceOf(recipient) + amount > maxWalletAmount
        ) revert MaxWalletReached();

        bool takeFee = !isSwappingFees &&
            _shouldTakeTransferTax(sender, recipient);
        bool isBuy = isBoltPair(sender);
        bool isSell = isBoltPair(recipient);
        bool isIndirectSwap = (_isBoltPair[sender] ||
            _isCachedAutodetectedBoltPair[_currentCacheVersion][sender]) &&
            (_isBoltPair[recipient] ||
                _isCachedAutodetectedBoltPair[_currentCacheVersion][recipient]);
        takeFee = takeFee && (indirectSwapFeeEnabled || !isIndirectSwap);

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwapFees = contractTokenBalance >= swapFeesAtAmount;
        bool isEOATransfer = sender.code.length == 0 &&
            recipient.code.length == 0;

        if (
            canSwapFees &&
            swappingFeesEnabled &&
            !isSwappingFees &&
            !_isLiquidityManagementPhase &&
            !isIndirectSwap &&
            (isSell || isEOATransfer) &&
            !isExcludedFromFee[sender] &&
            !isExcludedFromFee[recipient]
        ) {
            isSwappingFees = true;
            _swapFees();
            isSwappingFees = false;
        }

        uint256 totalFeeAmount;
        if (takeFee) {
            if (isSell) {
                totalFeeAmount = _takeSellFee(sender, sender, amount);
                totalFeeAmount += _takeSniperSellFee(sender, amount);
            } else if (isBuy) {
                totalFeeAmount = _takeBuyFee(sender, recipient, amount);
                totalFeeAmount += _takeSniperBuyFee(sender, amount);
            }
        }

        super._transfer(sender, recipient, amount - totalFeeAmount);
    }

    /************************************************************************/

    function _swapFees() internal {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 amountToSwap = contractTokenBalance > maxSwapFeesAmount
            ? maxSwapFeesAmount
            : contractTokenBalance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapPairToken;

        _approve(address(this), address(swapFeesRouter), amountToSwap);
        swapFeesRouter.swapExactTokensForTokens(
            amountToSwap,
            0,
            path,
            treasuryFeeRecipient,
            block.timestamp
        );
    }

    /************************************************************************/

    function isLiquidityManagementPhase() external view returns (bool) {
        return _isLiquidityManagementPhase;
    }

    function setLiquidityManagementPhase(
        bool isLiquidityManagementPhase_
    ) external onlyLiquidityManager {
        _isLiquidityManagementPhase = isLiquidityManagementPhase_;
    }

    /************************************************************************/

    function withdrawStuckEth(uint256 amount) public onlyOwner {
        (bool success, ) = address(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    function withdrawStuckEth() public onlyOwner {
        withdrawStuckEth(address(this).balance);
    }

    function withdrawStuckTokens(
        IERC20 token,
        uint256 amount
    ) public onlyOwner {
        bool success = token.transfer(msg.sender, amount);
        if (!success) revert TransferFailed();
    }

    function withdrawStuckTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        withdrawStuckTokens(token, balance);
    }

    function airdropHolders(
        address[] memory wallets,
        uint256[] memory amounts
    ) external onlyOwner {
        if (wallets.length != amounts.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < wallets.length; i++) {
            address wallet = wallets[i];
            uint256 amount = amounts[i];
            _transfer(msg.sender, wallet, amount);
        }
    }

    /************************************************************************/

    function isExcludedFromMaxWallet(
        address account
    ) public view returns (bool) {
        return _isExcludedFromMaxWallet[account] || _isBoltPair[account];
    }

    function excludeFromMaxWallet(address account) external onlyOwner {
        _isExcludedFromMaxWallet[account] = true;
    }

    function includeInMaxWallet(address account) external onlyOwner {
        _isExcludedFromMaxWallet[account] = false;
    }

    function setMaxWalletEnabled(bool enabled) external onlyOwner {
        maxWalletEnabled = enabled;
    }

    function setMaxWalletAmount(uint256 amount) external onlyOwner {
        maxWalletAmount = amount;
    }

    /************************************************************************/

    function addBoltPair(address _pair) external onlyOwner {
        _isBoltPair[_pair] = true;
        emit BoltPairAdded(_pair);
    }

    function removeBoltPair(address _pair) external onlyOwner {
        _isBoltPair[_pair] = false;
        emit BoltPairRemoved(_pair);
    }

    function excludeFromFee(address _account) external onlyOwner {
        isExcludedFromFee[_account] = true;
        emit AddressExcludedFromFees(_account);
    }

    function includeInFee(address _account) external onlyOwner {
        isExcludedFromFee[_account] = false;
        emit AddressIncludedInFees(_account);
    }

    function setFarmsFeeRecipient(address _account) external onlyOwner {
        if (_account == address(0)) {
            revert InvalidFeeRecipient();
        }
        farmsFeeRecipient = _account;
    }

    function setStakingFeeRecipient(address _account) external onlyOwner {
        if (_account == address(0)) {
            revert InvalidFeeRecipient();
        }
        stakingFeeRecipient = _account;
    }

    function setTreasuryFeeRecipient(address _account) external onlyOwner {
        if (_account == address(0)) {
            revert InvalidFeeRecipient();
        }

        treasuryFeeRecipient = _account;
    }

    function setBuyFees(
        uint256 _burnBuyFee,
        uint256 _farmsBuyFee,
        uint256 _stakingBuyFee,
        uint256 _treasuryBuyFee
    ) public onlyOwner {
        if (
            _burnBuyFee + _farmsBuyFee + _stakingBuyFee + _treasuryBuyFee >
            MAX_FEE
        ) {
            revert FeeTooHigh();
        }

        burnBuyFee = _burnBuyFee;
        farmsBuyFee = _farmsBuyFee;
        stakingBuyFee = _stakingBuyFee;
        treasuryBuyFee = _treasuryBuyFee;
        totalBuyFee = burnBuyFee + farmsBuyFee + stakingBuyFee + treasuryBuyFee;
    }

    function setSellFees(
        uint256 _burnSellFee,
        uint256 _farmsSellFee,
        uint256 _stakingSellFee,
        uint256 _treasurySellFee
    ) public onlyOwner {
        if (
            _burnSellFee + _farmsSellFee + _stakingSellFee + _treasurySellFee >
            MAX_FEE
        ) {
            revert FeeTooHigh();
        }

        burnSellFee = _burnSellFee;
        farmsSellFee = _farmsSellFee;
        stakingSellFee = _stakingSellFee;
        treasurySellFee = _treasurySellFee;
        totalSellFee =
            burnSellFee +
            farmsSellFee +
            stakingSellFee +
            treasurySellFee;
    }

    function setLiquidityManager(
        address _liquidityManager,
        bool _isManager
    ) public onlyOwner {
        isLiquidityManager[_liquidityManager] = _isManager;
    }

    function addWhitelistedFactory(address _factory) public onlyOwner {
        isWhitelistedFactory[_factory] = true;
    }

    function removeWhitelistedFactory(address _factory) public onlyOwner {
        isWhitelistedFactory[_factory] = false;
        _currentCacheVersion++;
    }

    function setIndirectSwapFeeEnabled(
        bool _indirectSwapFeeEnabled
    ) public onlyOwner {
        indirectSwapFeeEnabled = _indirectSwapFeeEnabled;
    }

    function enableTrading() public onlyOwner {
        if (tradingEnabled) revert TradingAlreadyEnabled();
        tradingEnabled = true;

        if (tradingEnabledTimestamp < block.timestamp) {
            tradingEnabledTimestamp = block.timestamp;
        }

        swappingFeesEnabled = true;
    }

    function setTradingEnabledTimestamp(uint256 _timestamp) public onlyOwner {
        if (tradingEnabled && tradingEnabledTimestamp <= block.timestamp) {
            revert TradingAlreadyEnabled();
        }

        if (tradingEnabled && _timestamp < block.timestamp) {
            revert TimestampIsInThePast();
        }

        tradingEnabledTimestamp = _timestamp;
    }

    function setPairAutoDetectionEnabled(
        bool _pairAutoDetectionEnabled
    ) public onlyOwner {
        pairAutoDetectionEnabled = _pairAutoDetectionEnabled;
    }

    function setSniperBuyFeeEnabled(
        bool _sniperBuyFeeEnabled
    ) public onlyOwner {
        sniperBuyFeeEnabled = _sniperBuyFeeEnabled;
    }

    function setSniperSellFeeEnabled(
        bool _sniperSellFeeEnabled
    ) public onlyOwner {
        sniperSellFeeEnabled = _sniperSellFeeEnabled;
    }

    function setSwapFeesAtAmount(uint256 _swapFeesAtAmount) public onlyOwner {
        swapFeesAtAmount = _swapFeesAtAmount;
    }

    function setMaxSwapFeesAmount(uint256 _maxSwapFeesAmount) public onlyOwner {
        maxSwapFeesAmount = _maxSwapFeesAmount;
    }

    function setSwappingFeesEnabled(
        bool _swappingFeesEnabled
    ) public onlyOwner {
        swappingFeesEnabled = _swappingFeesEnabled;
    }

    function setSwapFeesRouter(address _swapFeesRouter) public onlyOwner {
        swapFeesRouter = IBoltSwapV2Router01(_swapFeesRouter);
    }

    function setFeeDiscountOracle(IFeeDiscountOracle _oracle) public onlyOwner {
        feeDiscountOracle = _oracle;
    }

    function addBot(address account) public onlyOwner {
        isBot[account] = true;
    }

    function removeBot(address account) public onlyOwner {
        isBot[account] = false;
    }
}