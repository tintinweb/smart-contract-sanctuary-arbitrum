/**
 *Submitted for verification at Arbiscan on 2023-04-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

contract ChadBid is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 100000000 * 10 ** _decimals;
    string private constant _name = "Chad Bid";
    string private constant _symbol = "CHAD";

    uint256 public buyMarketingFees = 15;
    uint256 public sellMarketingFees = 15;
    uint256 public sellChadFees = 2;

    uint256 public maxTxAmount = _tTotal.mul(1).div(100);
    uint256 public maxWallet = _tTotal.mul(1).div(100);
    uint256 public swapIn = 100000 * 10 ** _decimals;

    struct Chad {
        address addr;
        uint256 amount;
        uint256 startAt;
        uint256 endAt;
        uint256 collectedFees; // NOTE: In ETH
    }

    Chad private _chadSlot0;
    Chad private _chadSlot1;
    address private _marketingWallet =
        0xAC23B9B8ebf3e1a8C9Ea0B2Fabf1AA270485c072;

    mapping(address => uint256) public trackingFees;

    uint256 private _roundDuration = 1 hours;
    uint256 private _roundStart = block.timestamp;

    uint256 public totalFees;
    bool public tradingActive = false;
    bool public chadActive = false;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    event NewChad(
        address indexed _addr,
        uint256 _amount,
        uint256 _startAt,
        uint256 _endAt
    );
    event ChadFees(
        address indexed _addr,
        uint256 _fees,
        uint256 _collectedFees
    );

    /**
     * @dev Constructor
     */
    constructor() {
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[_msgSender()] = true;

        uniswapV2Router = IUniswapV2Router02(
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        );

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        _balances[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!tradingActive) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Trading is not active"
            );
        }

        bool chadModel = true;
        uint256 marketingFees = 0;
        uint256 chadFees = 0;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            chadModel = false;
        }

        // NOTE: only take fees on buys/sells, do not take on wallet transfers
        if (chadModel) {
            require(
                amount <= maxTxAmount,
                "Transfer amount exceeds the maximum transaction amount"
            );

            if (to != uniswapV2Pair) {
                require(
                    balanceOf(to).add(amount) <= maxWallet,
                    "You are exceeding maximum wallet"
                );
            }

            // Buy logic
            if (uniswapV2Pair == from) {
                if (chadActive) {
                    Chad memory chad = getNextChadDetails();

                    if (amount > chad.amount) {
                        _setNextChad(to, amount);
                    }
                }

                marketingFees = amount.mul(buyMarketingFees).div(100);
            }

            // Sell logic
            if (uniswapV2Pair == to) {
                marketingFees = amount.mul(sellMarketingFees).div(100);

                if (chadActive) {
                    chadFees = amount.mul(sellChadFees).div(100);
                }

                if (balanceOf(address(this)) >= swapIn) {
                    _swapAndSendFees(
                        _marketingWallet,
                        balanceOf(address(this))
                    );
                }
            }

            if (marketingFees > 0) {
                _balances[address(this)] += marketingFees;
            }

            if (chadFees > 0) {
                _balances[address(this)] += chadFees;
                Chad memory chad = getCurrentChadDetails();

                uint256 chadReceivedFees = _swapAndSendFees(
                    chad.addr,
                    chadFees
                );
                _incureaseCurrentChadFees(chadReceivedFees);
                _incureaseTotalFees(chadReceivedFees);
            }
        }

        uint256 overallFees = marketingFees.add(chadFees);
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(overallFees));

        emit Transfer(from, to, amount);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function getUniswapPair() external view returns (address) {
        return uniswapV2Pair;
    }

    // Algorithm for remaining time to next round
    function remainingToNextRound() public view returns (uint256) {
        uint256 diffTime = block.timestamp - _roundStart;
        uint256 sHours = diffTime / _roundDuration;
        uint256 remaining = diffTime - sHours * _roundDuration;
        uint256 result = _roundDuration - remaining;

        return result;
    }

    function nextRoundAt() public view returns (uint256) {
        uint256 result = block.timestamp + remainingToNextRound();

        return result;
    }

    function getCurrentChadDetails() public view returns (Chad memory) {
        uint256 currentChadSlot = _currentChadSlot();

        if (currentChadSlot == 0) {
            return _chadSlot0;
        } else if (currentChadSlot == 1) {
            return _chadSlot1;
        } else {
            return Chad(_marketingWallet, 0, 0, 0, 0);
        }
    }

    function getNextChadDetails() public view returns (Chad memory) {
        uint256 nextChadSlot = _nextChadSlot();

        if (nextChadSlot == 0) {
            return _chadSlot0;
        } else if (nextChadSlot == 1) {
            return _chadSlot1;
        } else {
            return Chad(_marketingWallet, 0, 0, 0, 0);
        }
    }

    function _currentChadSlot() private view returns (uint256) {
        if (
            _chadSlot0.startAt < block.timestamp &&
            _chadSlot0.endAt >= block.timestamp
        ) {
            return 0;
        } else if (
            _chadSlot1.startAt < block.timestamp &&
            _chadSlot1.endAt >= block.timestamp
        ) {
            return 1;
        } else {
            return 2;
        }
    }

    function _nextChadSlot() private view returns (uint256) {
        if (
            _chadSlot0.startAt > block.timestamp &&
            _chadSlot0.endAt > block.timestamp
        ) {
            return 0;
        } else if (
            _chadSlot1.startAt > block.timestamp &&
            _chadSlot1.endAt > block.timestamp
        ) {
            return 1;
        } else {
            return 2;
        }
    }

    function _setNextChad(address addr, uint256 amount) private {
        Chad storage chad;

        uint256 nextChadSlot = _nextChadSlot();
        uint256 currentChadSlot = _currentChadSlot();

        if (
            (nextChadSlot == 0 && currentChadSlot == 1) ||
            (nextChadSlot == 2 && currentChadSlot == 1)
        ) {
            chad = _chadSlot0;
        } else if (
            (nextChadSlot == 1 && currentChadSlot == 0) ||
            (nextChadSlot == 2 && currentChadSlot == 0)
        ) {
            chad = _chadSlot1;
        } else {
            chad = _chadSlot0;
        }

        chad.addr = addr;
        chad.amount = amount;
        chad.startAt = nextRoundAt();
        chad.endAt = nextRoundAt() + _roundDuration;
        chad.collectedFees = 0;

        emit NewChad(addr, amount, chad.startAt, chad.endAt);
    }

    function _incureaseCurrentChadFees(uint256 fees) private {
        Chad storage chad;
        uint256 currentChadSlot = _currentChadSlot();

        if (currentChadSlot == 0) {
            chad = _chadSlot0;
            chad.collectedFees += fees;
        } else if (currentChadSlot == 1) {
            chad = _chadSlot1;
            chad.collectedFees += fees;
        } else {
            return;
        }

        trackingFees[chad.addr] += fees;

        emit ChadFees(chad.addr, fees, chad.collectedFees);
    }

    function _incureaseTotalFees(uint256 fees) private {
        totalFees += fees;
    }

    function _swapAndSendFees(
        address beneficiary,
        uint256 tokenAmount
    ) private returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256[] memory amountsOut = uniswapV2Router.getAmountsOut(
            tokenAmount,
            path
        );

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            beneficiary,
            block.timestamp
        );

        return amountsOut[1];
    }

    function forceSwap() external {
        require(
            _msgSender() == _marketingWallet,
            "Only marketing wallet can call this function"
        );

        uint256 contractTokenBalance = balanceOf(address(this));
        _swapAndSendFees(_marketingWallet, contractTokenBalance);

        if (address(this).balance > 0) {
            payable(_marketingWallet).transfer(address(this).balance);
        }
    }

    function changeRoundDuration(uint256 newDuration) external {
        require(
            _msgSender() == _marketingWallet,
            "Only Marketing wallet can call this function"
        );

        _roundDuration = newDuration;
    }

    function startTrading() external onlyOwner {
        tradingActive = true;
    }

    function startChadModel() external onlyOwner {
        chadActive = true;
    }

    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _tTotal;
        maxWallet = _tTotal;
    }

    function resetFees(
        uint256 buyMarketingFee,
        uint256 sellMarketingFee,
        uint256 sellChadFee
    ) external onlyOwner {
        require(buyMarketingFee <= 25, "Buy marketing fee too high");
        require(sellMarketingFee <= 25, "Sell marketing fee too high");
        require(sellChadFee <= 25, "Sell chad fee too high");

        buyMarketingFees = buyMarketingFee;
        sellMarketingFees = sellMarketingFee;
        sellChadFees = sellChadFee;
    }
}