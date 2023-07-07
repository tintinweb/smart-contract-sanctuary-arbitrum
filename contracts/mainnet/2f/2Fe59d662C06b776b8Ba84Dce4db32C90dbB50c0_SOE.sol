/**
 *Submitted for verification at Arbiscan on 2023-07-07
*/

/*
    SOE - Seasons Of ETH
    Telegram : https://t.me/seasons_portal_bot
    Dev : https://t.me/LetsStartARebellion
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;


// ERC Standard Objects 
// --------------------------------------------------------------
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
} 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function _onlyOwner() private view {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
} 
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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
    function _createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: cannot send to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// Safe Math Helpers 
// --------------------------------------------------------------
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
} 
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
} 
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
} 

// Uniswap Router 
// --------------------------------------------------------------
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function allPairsLength() external view returns (uint256);
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
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
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
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
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SOE Nft Tracker Interface
// --------------------------------------------------------------
interface ISOENftTracker {
  function isHolder ( address owner ) external view returns ( bool );
  function balanceOf ( address owner ) external view returns ( uint256 );
}


// Main Contract Logic 
// --------------------------------------------------------------
contract SOE is  ERC20, Ownable {
    // Imports
    using SafeMath for uint256; 
    
    // The Linked NFT Tracker Contract
    ISOENftTracker public SOENftTracker;  
    bool public isNFTSellBonusEnabled;
    bool public isNFTPreSeasonSellBonusEnabled; 
 
    // Tokens prior to swap  
    uint256 public minimumTokensBeforeSwap; 
    uint256 public maximumTokensForSwap; 
 
    // wallets 
    address public marketingWallet; // main marketing wallet
    address[] public additionalMarketingWallets; // raffle / additional marketing wallets
    uint256[] public additionalMarketingWalletsDistributionPercent ; // 5 = 0.5%
    uint256 public additionalMarketingDistributionPercentDivision = 1000; 
    mapping (address => bool) public isAdditionalMarketingWallet;
    address[] public operationWallets; // team operation wallets
    mapping (address => bool) public isOperationsWallet;
    address public transferWallet; // fees from transfers
    
    // seasons logic
    bool public isBuySeason = true;
    bool public isSellSeason;
    uint256 public nftHolderSellBonus = 2; // bonus % of bag allowed 
    uint256 public sellSeasonSellLimit = 10; // % of bag allowed
    uint256 public nftHolderSellMaxBonus = 8; // bonus % of bag allowed 
    uint256 public sellSeasonSellLimitDivision = 100; // % Division
    uint256 public sellSeasonThresholdHours = 24; // hours allowed per sale ( x% per sellSeasonThresholdHours)
    mapping (address => uint256) public sellSeasonLastSellDateTime;

    // distribution records
    uint256 public tokensForLiquidity;
    uint256 public tokensForMarketing;
    uint256 public tokensForReflections;
    uint256 public tokensForOperations;
    uint256 public tokensForTransfers;
    uint256 private liquidityDistributionTokens; 
    uint256 private marketingDistributionTokens;
    uint256 private reflectionsDistributionTokens; 
    uint256 private operationsDistributionTokens; 
    uint256 private transferDistributionTokens;

    // statistics    
    struct SeasonalStats{    
        uint256 seasonID;
        uint256 buySeasonBuys;
        uint256 buySeasonSells;
        uint256 sellSeasonBuys;
        uint256 sellSeasonSells;
        uint256 transfers;
    }
    mapping(uint256 => SeasonalStats) public soeStats; 
    uint256 public currentSeasonID;

    // taxes
    struct Taxes{    
        uint256 liquidity;
        uint256 marketing;
        uint256 reflections;
        uint256 operations; 
        uint256 total; 
    }
    
    struct SeasonalTaxes{    
        Taxes buy;
        Taxes sell; 
    }

    // buy / sell / transder season fees     
    SeasonalTaxes public buySeasonTaxes; 
    SeasonalTaxes public sellSeasonTaxes; 
    uint256 public seasonChangeTimestamp;
    uint256 public seasonChangeCooldownTimer = 30; //default cooldown 30s
    uint256 public seasonChangeMinimumThreshold = 1209600; //default cooldown 2 weeks
    uint256 public transferFee = 20; 

    // max amounts    
    bool public isMaxWalletEnabled = true;
    uint256 public maxWalletAmount; //max wallet holding
    mapping (address => bool) public isExcludedFromMaxWallet; 
    mapping (address => bool) public isExcludedFromFee; 

     // Limit variables for bot protection
    bool public limitsInEffect = true; //boolean used to turn limits on and off 
       
    // Router Information    
    mapping (address => bool) public isMarketPair;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair; 
    
    // toggle swap back (fees)  
    bool private inSwap;  
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    // Launch Settings
    bool public tradingOpen;        
 
    // dividend logic    
    SOEDividendTracker public dividendTracker;
    uint256 public gasForProcessing = 300000; // use by default 300,000 gas to process auto-claiming dividends

    // soe events      
    event SOENftTrackerUpdated(address indexed newContract); 
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event TranferWalletUpdated(address indexed newTranferWallet, address indexed oldTranferWallet);
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event AdditionalMarketingWalletAdded(address indexed newAdditionalMarketingWallet); 
    event AdditionalMarketingWalletRemoved(address indexed oldAdditionalMarketingWallet); 
    event OperationsWalletAdded(address indexed newOperationsWallet); 
    event OperationsWalletRemoved(address indexed oldOperationsWallet); 
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity); 
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event ProcessTaxesAndDiviends(uint256 tokensForLiquidity, uint256 tokensForMarketing, uint256 tokensForReflections, uint256 tokensForOperations, uint256 tokensForTransfers);
     
    // dividends events    
    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
    event ProcessedDividendTracker(uint256 iterations,uint256 claims,uint256 lastProcessedIndex,bool indexed automatic,uint256 gas,address indexed processor);

    constructor() ERC20("SeasonsOfETH", "SOE", 18) {
 
        // create new dividend tracker        
    	dividendTracker = new SOEDividendTracker();

        // create new Seasonsal Stats
        soeStats[currentSeasonID] = SeasonalStats({  
                seasonID: currentSeasonID,
                buySeasonBuys: 0,
                buySeasonSells: 0, 
                sellSeasonBuys: 0,
                sellSeasonSells:0,
                transfers: 0        
            });
        
        // set season taxes
        buySeasonTaxes = SeasonalTaxes({
            buy: Taxes({
                liquidity: 2,
                marketing: 2,
                reflections: 4,
                operations:  2,
                total:  10
            }),
            sell: Taxes({
                liquidity: 10,
                marketing: 12,
                reflections: 35,
                operations:  12,
                total:  69
            })
        }); 
        sellSeasonTaxes = SeasonalTaxes({
            buy: Taxes({
                liquidity: 4,
                marketing: 4,
                reflections: 10,
                operations:  2,
                total:  20
            }),
            sell: Taxes({
                liquidity: 1,
                marketing: 0,
                reflections: 1,
                operations:  2,
                total:  4
            })
        });  

        // create router ------------------------------
        IUniswapV2Router02 _uniswapV2Router;
        if (block.chainid == 42161) { // Arbitrum One
            _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        } else revert();

         // Create a uniswap pair for this new token         
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())     
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router; 
        isMarketPair[address(uniswapPair)] = true;

        // set allowances        
        uint256 totalSupply = 1 * 1e9 * 1e18; // 1 billion 
        minimumTokensBeforeSwap = (totalSupply * 25) / 100000; // 0.025% swap tokens amount 
        maximumTokensForSwap = (totalSupply * 200) / 100000; // 0.2% swap tokens amount   
        maxWalletAmount = (totalSupply * 15) / 1000; //max wallet limit of 1.5% 
                
        // add required operations wallets
        operationWallets.push(0xa8B92CB77146cFAB21648B5d7DD91AADAf71Aaa3); // Pasta
        isOperationsWallet[0xa8B92CB77146cFAB21648B5d7DD91AADAf71Aaa3] = true;        
        operationWallets.push(0xBE561612506B9ce2B40b8E116Cb778cF0ad959aB); // Rens
        isOperationsWallet[0xBE561612506B9ce2B40b8E116Cb778cF0ad959aB] = true;
        
        // add marketing wallets
        marketingWallet = payable(0x930Bc6Fa8456cf74D20c530D08921E8F6fAA9c4A); // main
        additionalMarketingWallets.push(0x6a97C8BaC8599de996f80684b2cb18B7698B46d0); // raffle
        additionalMarketingWalletsDistributionPercent.push(5); // 5 = 0.5%
        isAdditionalMarketingWallet[0x6a97C8BaC8599de996f80684b2cb18B7698B46d0] = true;    
        additionalMarketingWallets.push(0x31c97185F37B5daCb6f667dA130dD3c8D360186a); // dividend processor
        additionalMarketingWalletsDistributionPercent.push(5); // 5 = 0.5%
        isAdditionalMarketingWallet[0x31c97185F37B5daCb6f667dA130dD3c8D360186a] = true;    

        // add transfer wallet
        transferWallet = payable(0xEb4548d0C8100Bd70C1B507203a9d0877cEfB53d);
       
        // exclude from paying fees 
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[address(0x000000000000000000000000000000000000dEaD)] = true; 
        isExcludedFromFee[marketingWallet] = true;  
    
        // exclude from max wallet size
        isExcludedFromMaxWallet[owner()] = true;
        isExcludedFromMaxWallet[address(this)] = true;
        isExcludedFromMaxWallet[address(0x000000000000000000000000000000000000dEaD)] = true; 
        isExcludedFromMaxWallet[address(uniswapPair)] = true; 

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD)); 
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(uniswapV2Router));
        dividendTracker.excludeFromDividends(address(uniswapPair));

        // create initial supply
        _createInitialSupply(owner(), totalSupply);  
    }

    receive() external payable {}    
    
    // validation    
    // -------------------------------
    function verifyAddress(address newAddress) internal pure { 
        require(newAddress != address(0), "Cannot set to address 0");
    }  

    function verifyNonActiveSeason(bool activeSeason) internal pure { 
        require(!activeSeason, "cannot modify for active season");
    } 

    function verifyActiveSeasonTaxChange(bool criteria) internal pure { 
        require(criteria, "cannot increase taxes during active season");
    }   

    function verifySeasonCanChange() internal view {        
        require(block.timestamp >= seasonChangeTimestamp + seasonChangeMinimumThreshold, "minimum active season time not met");
    }
 
    // nft interaction methods    
    // -------------------------------

    // set SOE NFT Tracker
    function updateNFTTracker(address newAddress) external onlyOwner { 
        verifyAddress(newAddress); 
        SOENftTracker = ISOENftTracker(newAddress);  
        emit SOENftTrackerUpdated(newAddress); 
    } 
    
    // update sell season nft holder bonus bag percent limit
    function setNFTHolderSellBonus(uint256 newLimit) external onlyOwner {
        nftHolderSellBonus = newLimit;
    } 

    // update sell season nft holder max bonus bag percent limit
    function setNFTHolderSellMaxBonus(uint256 newLimit) external onlyOwner {
        nftHolderSellMaxBonus = newLimit;
    }  

    // enable nft bonus
    function enableNFTSellBonus(bool status) external onlyOwner {
        isNFTSellBonusEnabled = status;
    }

    // enable ability to sell before sell season kicks off
    function enableNFTPreSeasonSellBonus(bool status) external onlyOwner {
        isNFTPreSeasonSellBonusEnabled = status;
    }  

     // check if address is nft holder
    function isNFTHolder(address account) public view returns (bool) {        
        return SOENftTracker.isHolder(account);
    } 
    
    // calculate the amount of nfts held
    function getNFTsHeld(address account) public view returns (uint256) {
        return SOENftTracker.balanceOf(account); 
    }  

    // dividend interaction methods    
    // -------------------------------

    // link new dividend contract
    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker), "The dividend tracker already has that address");

        SOEDividendTracker newDividendTracker = SOEDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this), "The new dividend tracker must be owned by the SOE token contract");
        
        newDividendTracker.excludeFromDividends(address(newDividendTracker));
        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD)); 
        newDividendTracker.excludeFromDividends(owner());
        newDividendTracker.excludeFromDividends(address(uniswapPair));

        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
    }         

    // update minimum balance required for dividends
    function getMinimumBalanceForDividends() external view returns (uint256)  {
        return dividendTracker.minimumTokenBalanceForDividends();
    }
    // update minimum balance required for dividends
    function updateMinimumBalanceForDividends(uint256 newMinimumBalance) external onlyOwner {
        dividendTracker.updateDividendMinimum(newMinimumBalance);
    }
    // excludes wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }
    // removes exclusion on wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function includeInDividends(address account) external onlyOwner {
        dividendTracker.includeInDividends(account);
    }
    // update manual claim time
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    } 
    // get claim wait time
    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }
    // total dividends distributed in ETH
    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }
    // get value of pending dividends for address
    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}
    // holder balance with dividends
    function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.holderBalance(account);
	}
    // get dividend account info
    function getAccountDividendsInfo(address account) external view returns (address,int256,int256,uint256,uint256,uint256,uint256,uint256) {
        return dividendTracker.getAccount(account);
    }
    // get dividend info at index
    function getAccountDividendsInfoAtIndex(uint256 index) external view returns (address,int256,int256,uint256,uint256,uint256,uint256,uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }	    
    // allow a user to manual process all dividends.
    function processDividendTracker(uint256 gas) external {
        (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gas);
		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, false, gas, tx.origin);
    }
  	// allows a user to manually claim their tokens.
  	function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
    }    
    // get last processed index
    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }
    // get number of curretn dividend addresses
    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

  	// @dev Owner functions start -------------------------------------
    
    // update max tx amount
    function setMaxWalletAmount(uint256 newAmount) external onlyOwner() {
        require(newAmount >= (totalSupply() / 1000), "max wallet cannot be set to less than 0.1%");
        maxWalletAmount = newAmount;
    }

    // enable max wallet restriction
    function enableMaxWallet(bool status) external onlyOwner() {
        isMaxWalletEnabled = status;
    }

    // set excluded wallet limit 
    function setIsExcludedFromMaxWallet(address holder, bool exempt) external onlyOwner {
        isExcludedFromMaxWallet[holder] = exempt;
    } 

    function createNewSeason() external onlyOwner {
        // create new Seasonsal Stats
        require(isSellSeason, "Cannot start during a buy season"); 
        verifySeasonCanChange();
        currentSeasonID ++; 
        
        soeStats[currentSeasonID] = SeasonalStats({  
            seasonID: currentSeasonID,
            buySeasonBuys: 0,
            buySeasonSells: 0, 
            sellSeasonBuys: 0,
            sellSeasonSells:0,
            transfers: 0        
        }); 
        isSellSeason = false;
        isBuySeason = true;
        seasonChangeTimestamp = block.timestamp;
    }
    // enable sell season
    function enableSellSeason() external onlyOwner {
        verifySeasonCanChange();
        isBuySeason = false;
        isSellSeason = true;
        seasonChangeTimestamp = block.timestamp;
    }
    // update sell season bag percent limit
    function setSellSeasonBagPercent(uint256 newSellSeasonSellLimit, uint256 newSellSeasonSellLimitDivision) external onlyOwner {     
        verifyNonActiveSeason(isSellSeason);
        require(newSellSeasonSellLimit > 0, "value must be > 0");
        require(newSellSeasonSellLimitDivision > 0, "value must be > 0");
        sellSeasonSellLimit = newSellSeasonSellLimit;
        sellSeasonSellLimitDivision = newSellSeasonSellLimitDivision;
    } 
    // update sell hour threshold
    function setSellSeasonThresholdHours(uint256 newLimit) external onlyOwner {     
        verifyNonActiveSeason(isSellSeason);
        require(newLimit <= 168, "value must be <= 168"); // 1 week  
        sellSeasonThresholdHours = newLimit;
    }    
    // toogle market pair status
    function setMarketPairStatus(address account, bool newValue) public onlyOwner {
        isMarketPair[account] = newValue;
        if(newValue) {
            dividendTracker.excludeFromDividends(account);
        }
    }

    // set excluded tax 
    function setIsExcludedFromFee(address account, bool newValue) public onlyOwner {
        isExcludedFromFee[account] = newValue;
    }

    // get current taxes based on season
    function getCurrentEnabledBuyTax() external view returns(uint256) {
        return (isBuySeason) ? buySeasonTaxes.buy.total : sellSeasonTaxes.buy.total;
    }
    function getCurrentEnabledSellTax() external view returns(uint256) {
        return (isBuySeason) ? buySeasonTaxes.sell.total : sellSeasonTaxes.sell.total;
    }
    
    // update buy season fees
    function updateBuySeasonBuyFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _reflectionsFee, uint256 _operationsFee) external onlyOwner {
        if(isBuySeason){
            uint256 newTotal = _liquidityFee + _marketingFee + _reflectionsFee + _operationsFee;
            verifyActiveSeasonTaxChange(newTotal <= buySeasonTaxes.buy.total);
        }
        buySeasonTaxes.buy = Taxes({
            liquidity: _liquidityFee,
            marketing: _marketingFee,
            reflections: _reflectionsFee,
            operations: _operationsFee,
            total:  _liquidityFee + _marketingFee + _reflectionsFee + _operationsFee
        }) ;
        require(buySeasonTaxes.buy.total <= 25, "value must be <= 15%");
    }
    function updateBuySeasonSellFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _reflectionsFee, uint256 _operationsFee) external onlyOwner {
        if(isBuySeason){
            uint256 newTotal = _liquidityFee + _marketingFee + _reflectionsFee + _operationsFee;
            verifyActiveSeasonTaxChange(newTotal <= buySeasonTaxes.sell.total); 
        }
        buySeasonTaxes.sell = Taxes({
            liquidity: _liquidityFee,
            marketing: _marketingFee,
            reflections: _reflectionsFee,
            operations: _operationsFee,
            total:  _liquidityFee + _marketingFee + _reflectionsFee + _operationsFee
        }) ; 
        require(buySeasonTaxes.sell.total <= 85, "value must be <= 70%");
    }

    // update sell season fees
    function updateSellSeasonBuyFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _reflectionsFee, uint256 _operationsFee) external onlyOwner {
        if(isSellSeason){
            uint256 newTotal = _liquidityFee + _marketingFee + _reflectionsFee + _operationsFee;
            verifyActiveSeasonTaxChange(newTotal <= sellSeasonTaxes.buy.total);  
        }
        sellSeasonTaxes.buy = Taxes({
            liquidity: _liquidityFee,
            marketing: _marketingFee,
            reflections: _reflectionsFee,
            operations: _operationsFee,
            total:  _liquidityFee + _marketingFee + _reflectionsFee + _operationsFee
        }) ;  
        require(sellSeasonTaxes.buy.total <= 25, "value must be <= 25%");
    }
    function updateSellSeasonSellFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _reflectionsFee, uint256 _operationsFee) external onlyOwner {
        if(isSellSeason){
            uint256 newTotal = _liquidityFee + _marketingFee + _reflectionsFee + _operationsFee;
            verifyActiveSeasonTaxChange(newTotal <= sellSeasonTaxes.sell.total);   
        }
        sellSeasonTaxes.sell = Taxes({
            liquidity: _liquidityFee,
            marketing: _marketingFee,
            reflections: _reflectionsFee,
            operations: _operationsFee,
            total:  _liquidityFee + _marketingFee + _reflectionsFee + _operationsFee
        }) ;  
        require(sellSeasonTaxes.sell.total <= 10, "value must be <= 10%"); 
    }

    // update transfer tax 
    function updateTransferFee(uint256 _fee) external onlyOwner {
        require(_fee <= 30, "value must be <= 30%"); 
        transferFee = _fee;
    }

    // get minimum tokens before swap
    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }   

    // change the minimum amount of tokens to sell from fees
    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        minimumTokensBeforeSwap = newLimit;
    }

    // get maximum tokens for swap
    function maximumTokensForSwapAmount() public view returns (uint256) {
        return maximumTokensForSwap;
    }    
    
    // change the maximum amount of tokens to sell from fees
    function setNumMaxTokensForSwap(uint256 newLimit) external onlyOwner() {
        maximumTokensForSwap = newLimit;
    }

    // updates the transfers wallet 
    function updateTransfersWallet(address newAddress) external onlyOwner {
        verifyAddress(newAddress);  
        transferWallet =  payable(newAddress);
        emit TranferWalletUpdated(newAddress, transferWallet);
    }
    
    // updates the marketing wallet (main team marketing)
    function updateMarketingWallet(address newAddress) external onlyOwner {
        verifyAddress(newAddress);  
        isExcludedFromFee[newAddress] = true;
        isExcludedFromFee[marketingWallet] = false;
        marketingWallet =  payable(newAddress);
        emit MarketingWalletUpdated(newAddress, marketingWallet);
    }
 
    // change the additional marketing wallet percent division
    function setAdditionalMarketingWalletPercentDivision(uint256 value) external onlyOwner() {
        additionalMarketingDistributionPercentDivision = value;
    } 
    
    // add new additional marketing wallet (justin, raffle, etc.)
    function addAdditionalMarketingWallet(address newAddress, uint256 distribution) external onlyOwner {
        verifyAddress(newAddress);  
        require(!isAdditionalMarketingWallet[newAddress], "Already an marketing wallet");
        additionalMarketingWallets.push(newAddress);
        additionalMarketingWalletsDistributionPercent.push(distribution);
        isAdditionalMarketingWallet[newAddress] = true;
        emit AdditionalMarketingWalletAdded(newAddress); 
    }    
    
    // remove additional marketing wallet (justin, raffle, etc.)
    function removeAdditionalMarketingWallet(address oldAddress) external onlyOwner {
        require(isAdditionalMarketingWallet[oldAddress], "Not currently an marketing wallet");
        isAdditionalMarketingWallet[oldAddress] = false;
       
        // remove wallet from active array
        uint256 removedIndex;
        bool walletRemoved = false;
        for(uint256 i = 0; i < additionalMarketingWallets.length; i++){
            if(additionalMarketingWallets[i] == oldAddress){         
                delete additionalMarketingWallets[i];     
                delete additionalMarketingWalletsDistributionPercent[i];
                removedIndex = i;
                walletRemoved = true;
                break;
            }
        }
        // move all elements up from the element we want to delete. Then pop the last element because it isn't needed anymore.
        if(walletRemoved){
            for (uint256 i = removedIndex; i < additionalMarketingWallets.length - 1; i++) {
                additionalMarketingWallets[i] = additionalMarketingWallets[i + 1];
                additionalMarketingWalletsDistributionPercent[i] = additionalMarketingWalletsDistributionPercent[i + 1];
            }
            additionalMarketingWallets.pop();
            additionalMarketingWalletsDistributionPercent.pop();
        }

        emit AdditionalMarketingWalletRemoved(oldAddress); 
    }     

    // add new operations wallet (servers, support, dev, etc.)
    function addOperationsWallet(address newAddress) external onlyOwner {
        verifyAddress(newAddress);  
        require(!isOperationsWallet[newAddress], "Already an operations wallet");
        operationWallets.push(newAddress);
        isOperationsWallet[newAddress] = true;
        emit OperationsWalletAdded(newAddress); 
    }    
    
    // remove operations wallet (servers, support, dev, etc.)
    function removeOperationsWallet(address oldAddress) external onlyOwner { 
        require(isOperationsWallet[oldAddress], "Not currently an operations wallet");
        isOperationsWallet[oldAddress] = false;
        
          // remove wallet from active array
        uint256 removedIndex;
        bool walletRemoved = false;
        for(uint256 i = 0; i < operationWallets.length; i++){
            if(operationWallets[i] == oldAddress){         
                delete operationWallets[i];
                removedIndex = i;
                walletRemoved = true;
                break;
            }
        }
        // move all elements up from the element we want to delete. Then pop the last element because it isn't needed anymore.
        if(walletRemoved){
            for (uint256 i = removedIndex; i < operationWallets.length - 1; i++) {
                operationWallets[i] = operationWallets[i + 1];
            }
            operationWallets.pop();
        }
        
        emit OperationsWalletRemoved(oldAddress); 
    }    

    // change router address
    function changeRouterAddress(address newRouterAddress) public onlyOwner returns(address newPairAddress) {

        address oldUniswapPair = uniswapPair;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouterAddress); 
        newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());

        // check if new pair deployed
        if(newPairAddress == address(0)) 
        {
            newPairAddress = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
        }

        uniswapPair = newPairAddress; 
        uniswapV2Router = _uniswapV2Router; 
        isMarketPair[address(uniswapPair)] = true; 
        isExcludedFromMaxWallet[address(uniswapPair)] = true;
        dividendTracker.excludeFromDividends(uniswapPair);
        emit UpdateUniswapV2Router(uniswapPair, oldUniswapPair);
    }

    // once enabled, can never be turned off
    function enableTrading() public onlyOwner {  
        tradingOpen = true;
    }
    
    // turn limits on and off
    function setLimitsInEffect(bool value) external onlyOwner {
        limitsInEffect = value;
    }
    
    // set cooldown timer, can only be between 0 and 300 seconds (5 mins max)
    function setSeasonChangeCooldown(uint256 cooldown) external onlyOwner {
        require(cooldown <= 300, "cooldown timer cannot exceed 5 minutes");
        seasonChangeCooldownTimer = cooldown;
    }
    
    // set cooldown timer, can only be between 0 and 300 seconds (5 mins max)
    function setSeasonChangeMinimumThreshold(uint256 threshold) external onlyOwner { 
        require(threshold >= 604800, "threshold cannot be below 1 week"); 
        seasonChangeMinimumThreshold = threshold;
    }
    
    // sell season transfer interaction methods     
    // -------------------------------
    // get address last sold date
    function getSellSeasonHoursToNextAllowedSell(address from) public view returns (uint256) {

        // if seller has sold before
        if(sellSeasonLastSellDateTime[from] > 0){

            // check if last sell is >= sellSeasonThresholdHours
            // 60 (to get the minutes), 60 (to get the hours) and 24 (to get the days)
            // e.g. ((block.timestamp - sellSeasonLastSellDateTime[from])  / 60 / 60 / 24); 
            uint256 daysDiff = ((block.timestamp - sellSeasonLastSellDateTime[from])  / 60 / 60); 

            if(daysDiff >= sellSeasonThresholdHours){
                return 0;
            }else{
                return sellSeasonThresholdHours - daysDiff;
            }  
        }

        return 0;
    } 
    // get address last sold date
    function verifySellSeasonAmountAllowed(address from) public view returns (uint256) { 
            
        // check amount to be sold is <= to allowed amount
        uint256 sellLimit = sellSeasonSellLimit;
        if(isNFTSellBonusEnabled){
            if(SOENftTracker.isHolder(from)){
                uint256 nftsHeld = SOENftTracker.balanceOf(from);
                uint256 nftBonusSellLimit = nftsHeld.mul(nftHolderSellBonus);

                if(nftBonusSellLimit > nftHolderSellMaxBonus){
                    nftBonusSellLimit = nftHolderSellMaxBonus;
                }
                sellLimit += nftBonusSellLimit;
            }
        }
        uint256 allowedSellAmount = balanceOf(from).mul(sellLimit).div(sellSeasonSellLimitDivision);
        return allowedSellAmount;
    }    
         
    // @dev Views start here ------------------------------------

    // @dev User Callable Functions start here! ---------------------------------------------  
    function _transfer(address from, address to, uint256 amount) internal override {
        
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        // early exit with no other logic if transfering 0 (to prevent 0 transfers from triggering other logic)
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        // check trading open
        if (!tradingOpen && from != owner()) {            
            revert("Trading has not yet been enabled");  
        } 

        uint256 contractTokenBalance = balanceOf(address(this));        
        bool canSwap = contractTokenBalance >= minimumTokensBeforeSwap;
        
        if(
            canSwap &&
            !inSwap &&
            isMarketPair[to] &&
            !isExcludedFromFee[from]
        ) {        
            swapBack(); 
        }

        bool takeFee = !inSwap;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(isExcludedFromFee[from] || isExcludedFromFee[to] || from == address(this)) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees;
                         
            // cooldown to stop delay traffic after season swap        
            if (limitsInEffect) {
                require(block.timestamp >= seasonChangeTimestamp + seasonChangeCooldownTimer, "cooldown period active");                        
            }

            // buy
            if(isMarketPair[from]) {
                // buy season
                if(isBuySeason && buySeasonTaxes.buy.total > 0){
                    fees = amount.mul(buySeasonTaxes.buy.total).div(100);
                    tokensForLiquidity += fees * buySeasonTaxes.buy.liquidity / buySeasonTaxes.buy.total;
                    tokensForMarketing += fees * buySeasonTaxes.buy.marketing / buySeasonTaxes.buy.total;
                    tokensForReflections += fees * buySeasonTaxes.buy.reflections / buySeasonTaxes.buy.total;
                    tokensForOperations += fees * buySeasonTaxes.buy.operations / buySeasonTaxes.buy.total;
                    soeStats[currentSeasonID].buySeasonBuys ++;
                     
                }
                // sell season
                else if(isSellSeason && sellSeasonTaxes.buy.total > 0){
                    fees = amount.mul(sellSeasonTaxes.buy.total).div(100);
                    tokensForLiquidity += fees * sellSeasonTaxes.buy.liquidity / sellSeasonTaxes.buy.total;
                    tokensForMarketing += fees * sellSeasonTaxes.buy.marketing / sellSeasonTaxes.buy.total;
                    tokensForReflections += fees * sellSeasonTaxes.buy.reflections / sellSeasonTaxes.buy.total;
                    tokensForOperations += fees * sellSeasonTaxes.buy.operations / sellSeasonTaxes.buy.total;
                    soeStats[currentSeasonID].sellSeasonBuys ++;

                } 
            }
            // sell
            else if(isMarketPair[to]) {

                // if not sell season and nft pre sell bonus
                if(isNFTPreSeasonSellBonusEnabled && SOENftTracker.isHolder(from) || isSellSeason){  

                    // check if timeRemainingToAllowedSell is 0  
                    require(getSellSeasonHoursToNextAllowedSell(from) == 0, "You have sold your allowed sellSeasonThresholdHours amount"); 
                    
                    // check amount to be sold is <= to allowed amount  
                    require(amount <= verifySellSeasonAmountAllowed(from), "You are trying to sell more than allowed");  

                    // set sellers recorded datetime
                    sellSeasonLastSellDateTime[from] =  block.timestamp; 

                    if(sellSeasonTaxes.sell.total > 0){
                        fees = amount.mul(sellSeasonTaxes.sell.total).div(100);
                        tokensForLiquidity += fees * sellSeasonTaxes.sell.liquidity / sellSeasonTaxes.sell.total;
                        tokensForMarketing += fees * sellSeasonTaxes.sell.marketing / sellSeasonTaxes.sell.total;
                        tokensForReflections += fees * sellSeasonTaxes.sell.reflections / sellSeasonTaxes.sell.total;
                        tokensForOperations += fees * sellSeasonTaxes.sell.operations / sellSeasonTaxes.sell.total;                        
                        soeStats[currentSeasonID].sellSeasonSells ++;
                    }
                }
                
                // buy season
                else if(isBuySeason && buySeasonTaxes.sell.total > 0){
                    fees = amount.mul(buySeasonTaxes.sell.total).div(100);
                    tokensForLiquidity += fees * buySeasonTaxes.sell.liquidity / buySeasonTaxes.sell.total;
                    tokensForMarketing += fees * buySeasonTaxes.sell.marketing / buySeasonTaxes.sell.total;
                    tokensForReflections += fees * buySeasonTaxes.sell.reflections / buySeasonTaxes.sell.total;
                    tokensForOperations += fees * buySeasonTaxes.sell.operations / buySeasonTaxes.sell.total;                      
                    soeStats[currentSeasonID].buySeasonSells ++;
                }  
            }
            // transfer
            else{
                fees = amount.mul(transferFee).div(100);
                tokensForTransfers += fees;
                
                // set sellers recorded datetime
                sellSeasonLastSellDateTime[from] =  block.timestamp;  
                sellSeasonLastSellDateTime[to] =  block.timestamp;             
                soeStats[currentSeasonID].transfers ++;
            }

            amount = amount.sub(fees);

            if(isMaxWalletEnabled  && !isExcludedFromMaxWallet[to]){
                require(balanceOf(to).add(amount) <= maxWalletAmount, "Wallet Limit Exceeded");
            }

            super._transfer(from, address(this), fees);
        }  

        super._transfer(from, to, amount);

        try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!inSwap) {
	    	uint256 gas = gasForProcessing;

	    	try dividendTracker.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
	    		emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
	    	} 
	    	catch {
	    	}
        }  
    } 

    // can perform swapback function 
    function canSwapBack() public view returns (bool) { 
        
        uint256 contractTokenBalance = balanceOf(address(this));        
        bool canSwap = contractTokenBalance >= minimumTokensBeforeSwap;
        
        if(canSwap && !inSwap) {        
           return true;
        }   
        return false; 
    }

    // swap tokens for fees and liq (trigger method) 
    function triggerProcessTaxesAndDiviends() external {
        if(canSwapBack()) {        
            emit ProcessTaxesAndDiviends(tokensForLiquidity, tokensForMarketing, tokensForReflections, tokensForOperations, tokensForTransfers);
            swapBack();  
        }    
    }

    // swap tokens for fees and liq
    function swapBack() private swapping {

        // get tokens for swap
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing + tokensForReflections + tokensForOperations + tokensForTransfers;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        // enforce max tokens for
        if(contractBalance > maximumTokensForSwap || totalTokensToSwap > maximumTokensForSwap){                    
            uint256 liquidityPercent = tokensForLiquidity.mul(100).div(totalTokensToSwap);
            uint256 marketingPercent = tokensForMarketing.mul(100).div(totalTokensToSwap);
            uint256 reflectionsPercent = tokensForReflections.mul(100).div(totalTokensToSwap);
            uint256 operationsPercent = tokensForOperations.mul(100).div(totalTokensToSwap);
            uint256 transferPercent = tokensForTransfers.mul(100).div(totalTokensToSwap);

            // distribution due
            liquidityDistributionTokens = maximumTokensForSwap.mul(liquidityPercent).div(100);
            marketingDistributionTokens = maximumTokensForSwap.mul(marketingPercent).div(100);
            reflectionsDistributionTokens = maximumTokensForSwap.mul(reflectionsPercent).div(100);
            operationsDistributionTokens = maximumTokensForSwap.mul(operationsPercent).div(100);
            transferDistributionTokens = maximumTokensForSwap.mul(transferPercent).div(100);

            contractBalance = maximumTokensForSwap;
            totalTokensToSwap = maximumTokensForSwap;   
        } 
        // percentage breakdown
        else{            
            liquidityDistributionTokens = tokensForLiquidity; 
            marketingDistributionTokens = tokensForMarketing;
            reflectionsDistributionTokens = tokensForReflections; 
            operationsDistributionTokens = tokensForOperations; 
            transferDistributionTokens = tokensForTransfers; 
        }

        // halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * liquidityDistributionTokens / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        
        // get initial ETH (safety net)
        uint256 initialETHBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(amountToSwapForETH); 
        
        // get available balance from conversion
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);        
        uint256 ethForOperations = ethBalance.mul(operationsDistributionTokens).div(totalTokensToSwap - (liquidityDistributionTokens/2));
        uint256 ethForReflections = ethBalance.mul(reflectionsDistributionTokens).div(totalTokensToSwap - (liquidityDistributionTokens/2));
        uint256 ethForMarketing = ethBalance.mul(marketingDistributionTokens).div(totalTokensToSwap - (liquidityDistributionTokens/2));  
        uint256 ethForTransfers = ethBalance.mul(transferDistributionTokens).div(totalTokensToSwap - (liquidityDistributionTokens/2));       
        uint256 ethForLiquidity = ethBalance - ethForOperations - ethForReflections - ethForMarketing - ethForTransfers;
              
        // update counters
        tokensForLiquidity = tokensForLiquidity.sub(liquidityDistributionTokens);
        tokensForOperations = tokensForOperations.sub(operationsDistributionTokens);
        tokensForReflections = tokensForReflections.sub(reflectionsDistributionTokens);
        tokensForMarketing = tokensForMarketing.sub(marketingDistributionTokens);
        tokensForTransfers = tokensForTransfers.sub(transferDistributionTokens);  
        liquidityDistributionTokens = 0; 
        marketingDistributionTokens = 0;
        reflectionsDistributionTokens = 0; 
        operationsDistributionTokens = 0; 
        transferDistributionTokens = 0; 

        // send liquidity
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, liquidityTokens);
        }
        bool success;

        // send reflections eth
        if(ethForReflections > 0){
            (success,) = address(dividendTracker).call{value: ethForReflections}(""); 
        } 
        
        // send operations eth
        if(ethForOperations > 0){
            uint256 operationSplit = ethForOperations.div(operationWallets.length);
            for(uint256 i = 0; i < operationWallets.length; i++){
                (success,) = address(operationWallets[i]).call{value: operationSplit}("");  
            }
        }
        
        // send transfers eth
        if(ethForTransfers > 0){ 
            (success,) = address(transferWallet).call{value: ethForTransfers}("");   
        }
        
        // send marketing eth
        if(ethForMarketing > 0){
            for(uint256 i = 0; i < additionalMarketingWallets.length; i++){
                uint256 marketingSplit = ethForMarketing.mul(additionalMarketingWalletsDistributionPercent[i]).div(additionalMarketingDistributionPercentDivision);
                (success,) = address(additionalMarketingWallets[i]).call{value: marketingSplit}("");   
            } 

            (success,) = address(marketingWallet).call{value: address(this).balance}("");                  
        }
    } 
    
    // swap tokens to eth
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this), 
            block.timestamp
        );
        emit SwapTokensForETH(tokenAmount, path);
    }

    // add liqiudity 
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            owner(),
            block.timestamp
        );
    }
    
    function airdropToWallets(address[] calldata airdropWallets, uint256[] calldata amount) external onlyOwner() {
        require(airdropWallets.length == amount.length, "Arrays must be the same length");
        uint256 tokenMinimumForDivs = dividendTracker.minimumTokenBalanceForDividends();
        for(uint256 i = 0; i < airdropWallets.length; i++){
            address wallet = airdropWallets[i];
            uint256 airdropAmount = amount[i];
            super._transfer(msg.sender, wallet, airdropAmount);
            if(airdropAmount >= tokenMinimumForDivs){
                dividendTracker.setBalance(payable(wallet), balanceOf(wallet));
            }
        }
    }
}

// Dividend Contract Logic
// Based on @author Roger Wu (https://github.com/roger-wu)
// -------------------------------------------------------------- 

/// @title Dividend-Paying Token Optional Interface 
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

/// @title Dividend-Paying Token Interface
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);

  /// @notice Distributes ether to token holders as dividends.
  /// @dev SHOULD distribute the paid ether to token holders as dividends.
  ///  SHOULD NOT directly transfer ether to token holders in this function.
  ///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
  function distributeDividends() external payable;

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
  function withdrawDividend() external;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmount The amount of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
}

/// @title Dividend-Paying Token
/// @dev allows anyone to pay and distribute ether to token holders as dividends 
contract DividendPayingToken is DividendPayingTokenInterface, DividendPayingTokenOptionalInterface, Ownable {
    
  // Imports
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  // see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;  
  uint256 internal magnifiedDividendPerShare;
  
  mapping (address => uint256) public holderBalance;
  uint256 public totalBalance;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor() {
  }

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    distributeDividends();
  }

  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether not distributed,
  ///     the magnified amount of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
  function distributeDividends() public override payable {
    require(totalBalance > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (msg.value).mul(magnitude) / totalBalance
      );
      emit DividendsDistributed(msg.sender, msg.value);

      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function withdrawDividend() external virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      (bool success,) = user.call{value: _withdrawableDividend, gas: 3000}("");

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }
 
  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(holderBalance[_owner]).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that increases tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _increase(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that reduces an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _reduce(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = holderBalance[account];
    holderBalance[account] = newBalance;
    if(newBalance > currentBalance) {
      uint256 increaseAmount = newBalance.sub(currentBalance);
      _increase(account, increaseAmount);
      totalBalance += increaseAmount;
    } else if(newBalance < currentBalance) {
      uint256 reduceAmount = currentBalance.sub(newBalance);
      _reduce(account, reduceAmount);
      totalBalance -= reduceAmount;
    }
  }
}

/// @title SOE Dividend Tracker
/// @dev records and process ETH dividends 
contract SOEDividendTracker is DividendPayingToken {
    
    // imports
    using SafeMath for uint256;
    using SafeMathInt for int256;

    // map of address and holdings
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }
    Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    // excluded from dividends i.e. dead address, AMM, etc..
    mapping (address => bool) public excludedFromDividends;
   
    // claim information
    mapping (address => uint256) public lastClaimTimes;
    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;
    
    // events
    event ExcludeFromDividends(address indexed account);
    event IncludeInDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken() {
    	claimWait = 1200;
        minimumTokenBalanceForDividends = 100 * 1e18; //must hold 100+ tokens to get divs
    }

    // get dividend address info
    function get(address key) private view returns (uint) {
        return tokenHoldersMap.values[key];
    }

    // get index of address
    function getIndexOfKey(address key) private view returns (int) {
        if(!tokenHoldersMap.inserted[key]) {
            return -1;
        }
        return int(tokenHoldersMap.indexOf[key]);
    }

    // get keys at dividend index
    function getKeyAtIndex(uint index) private view returns (address) {
        return tokenHoldersMap.keys[index];
    }

    // get size of dividend list
    function size() private view returns (uint) {
        return tokenHoldersMap.keys.length;
    }

    // set new account balance
    function set(address key, uint val) private {
        if (tokenHoldersMap.inserted[key]) {
            tokenHoldersMap.values[key] = val;
        } else {
            tokenHoldersMap.inserted[key] = true;
            tokenHoldersMap.values[key] = val;
            tokenHoldersMap.indexOf[key] = tokenHoldersMap.keys.length;
            tokenHoldersMap.keys.push(key);
        }
    }

    // remove wallet from dividend map
    function remove(address key) private {
        if (!tokenHoldersMap.inserted[key]) {
            return;
        }

        delete tokenHoldersMap.inserted[key];
        delete tokenHoldersMap.values[key];

        uint index = tokenHoldersMap.indexOf[key];
        uint lastIndex = tokenHoldersMap.keys.length - 1;
        address lastKey = tokenHoldersMap.keys[lastIndex];

        tokenHoldersMap.indexOf[lastKey] = index;
        delete tokenHoldersMap.indexOf[key];

        tokenHoldersMap.keys[index] = lastKey;
        tokenHoldersMap.keys.pop();
    }
    
    // catch to override dividend withdraw
    function withdrawDividend() pure external override {
        require(false, "SOE_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main SOE contract.");
    }

    // exclude address from dividends
    function excludeFromDividends(address account) external onlyOwner {
    	excludedFromDividends[account] = true;
    	_setBalance(account, 0);
    	remove(account);
    	emit ExcludeFromDividends(account);
    }

    // include address in dividends
    function includeInDividends(address account) external onlyOwner {
    	excludedFromDividends[account] = false;
    	emit IncludeInDividends(account);
    }
    
    function updateDividendMinimum(uint256 minimumToEarnDivs) external onlyOwner {
        minimumTokenBalanceForDividends = minimumToEarnDivs;
    }

    // update claim wait time for manual claims
    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1200 && newClaimWait <= 86400, "SOE_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "SOE_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    // get last processed payment index
    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    // get total count of token holders
    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    // get address distribution info
    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        
        account = _account; // address
        index = getIndexOfKey(account); // index in array of holders
        iterationsUntilProcessed = -1; // default 

        // if index exists (address is holder)
        if(index >= 0) {
            // calculate the position compared to last processed
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account); // get withdrawable amount of dividends 
        totalDividends = accumulativeDividendOf(account); // get total dividends paid to date
        lastClaimTime = lastClaimTimes[account]; // get last time claimed

        // get next available claim time
        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0; 

        // calculate next auto payment time (guess depends on volume etc)
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    // get account info at dividend index
    function getAccountAtIndex(uint256 index)
        external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
    	
        // if index doesnt exist return default empty object
        if(index >= size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        // else return account info
        address account = getKeyAtIndex(index);
        return getAccount(account);
    }

    // determine if address can auto claim
    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}
    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    // update users dividend balance
    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	
        // if excluded abort
        if(excludedFromDividends[account]) {
    		return;
    	}

        // if balance mets minimum requirements update dividend info
    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		set(account, newBalance);
    	}
        // else remove (encase of sell below threshold)
    	else {
            _setBalance(account, 0);
    		remove(account);
    	}

        // send dividends that are pending
    	processAccount(account, true);
    }

    // process pending dividends
    function process(uint256 gas) external returns (uint256, uint256, uint256) {
        
        // check of there are holders before processing any diviends
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

        // get last processed index
    	uint256 _lastProcessedIndex = lastProcessedIndex;

        // create dividends logic varaibles
    	uint256 gasUsed = 0;
    	uint256 gasLeft = gasleft();
    	uint256 iterations = 0;
    	uint256 claims = 0;

        // while gas remaining and iterations is less that total number of holders
    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
            
            // get next index
    		_lastProcessedIndex++;

            // if index outside array start again at 0 (first address)
    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

            // get account info
    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

            // if auto claim available for account.. process dividend
    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

            // increment iterations and update remaining gas
    		iterations++;
    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

        // update last processed index
    	lastProcessedIndex = _lastProcessedIndex;
    	return (iterations, claims, lastProcessedIndex);
    }

    // method to process current pending dividend value
    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}