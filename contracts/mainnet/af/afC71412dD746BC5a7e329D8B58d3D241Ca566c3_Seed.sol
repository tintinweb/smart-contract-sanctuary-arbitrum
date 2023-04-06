/**
 *Submitted for verification at Etherscan.io on 2023-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;


// 
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

// 
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

// 
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// 
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

// 
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)
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

// 
interface IPancakePair {
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

// 
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

// 
interface IPancakeFactory {
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

interface IPancakeRouter01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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

interface IPancakeRouter02 is IPancakeRouter01 {
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

// 
interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit(uint256 amount) external payable;
    function process(uint256 gas) external;
}

abstract contract ERC20Detailed is IERC20 {
    string public _name;
    string public _symbol;
    uint8 public _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// 
contract Seed is ERC20Detailed, Ownable, Pausable
{
    using SafeMath for uint256;
    using SignedMath for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    IPancakePair public pairContract;
    mapping(address => bool) public isFeeExempt;

    modifier validRecipient(address to) {
        require(to != address(0x0), "Null Address");
        _;
    }

    uint256 public constant DECIMALS = 5;
    uint256 public constant MAX_UINT256 = ~uint256(0);
    uint256 public constant MAX_GONS = uint256(~uint192(0));
    uint8 public constant RATE_DECIMALS = 7;

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY =
        25 * 10**3 * 10**DECIMALS;

    uint256 constant public RESOLUTION = 10000;

    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public ZERO = 0x0000000000000000000000000000000000000000;

    address public autoLiquidityReceiver;
    address public treasuryReceiver;
    address public insuranceFundReceiver;
    address public firePit;

    bool public swapEnabled;
    IPancakeRouter02 public router;
    address public pair;
    address public feeToken;
    address[] public feeTokenPath;

    bool inSwap;

    uint256 public ethRewardStore;

    uint256 private constant TOTAL_GONS =
        MAX_GONS - (MAX_GONS % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = 325 * 10**7 * 10**DECIMALS;

    bool public autoRebase;
    bool public autoAddLiquidity;
    uint256 public initRebaseStartTime;
    uint256 public lastRebasedTime;
    uint256 public lastAddLiquidityTime;

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => bool) public blacklist;

    uint256 public timeframeCurrent;
    uint256 public timeframeExpiresAfter;

    uint32 public maxTokenPerWalletPercent;

    uint256 public timeframeQuotaInPercentage;
    uint256 public timeframeQuotaOutPercentage;

    mapping(uint256 => mapping(address => int256)) public inAmounts;
    mapping(uint256 => mapping(address => uint256)) public outAmounts;

    bool public ethRewardEnabled;

    bool public disableAllFee;

    address public distributorAddress;
    uint256 public distributorGas;

    address public devAddress;
    uint256 public devFee;

    uint256 public liquidityFeeOnBuy;
    uint256 public treasuryFeeOnBuy;
    uint256 public ethFeeOnBuy;
    uint256 public insuranceFundFeeOnBuy;
    uint256 public firePitFeeOnBuy;
    uint256 public totalFeeOnBuy;

    uint256 public liquidityFeeOnSell;
    uint256 public treasuryFeeOnSell;
    uint256 public ethFeeOnSell;
    uint256 public insuranceFundFeeOnSell;
    uint256 public firePitFeeOnSell;
    uint256 public totalFeeOnSell;

    uint256 public maxLPSwapThreshold;
    uint256 public maxETHFeeSwapThreshold;

    uint256 public rebasePeriod;
    uint256 public rebaseRate;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(string memory name_, string memory symbol_, 
            address router_,
            address lr, address tr, address aifr, address fp, address dev)
    ERC20Detailed(name_, symbol_, uint8(DECIMALS))
        {
        swapEnabled = true;
        inSwap = false;

        router = IPancakeRouter02(router_); // 0x1b02da8cb0d097eb8d57a175b88c7d8b47997506

        pair = IPancakeFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        autoLiquidityReceiver = lr;
        treasuryReceiver = tr; 
        insuranceFundReceiver = aifr;
        firePit = fp;

        liquidityFeeOnBuy = 100;
        treasuryFeeOnBuy = 250;
        insuranceFundFeeOnBuy = 450; // here Dev fee are included here
        ethFeeOnBuy = 0;
        firePitFeeOnBuy = 0;
        totalFeeOnBuy = liquidityFeeOnBuy.add(treasuryFeeOnBuy).add(insuranceFundFeeOnBuy).add(firePitFeeOnBuy).add(ethFeeOnBuy);

        liquidityFeeOnSell = 100;
        treasuryFeeOnSell = 550;
        insuranceFundFeeOnSell = 450; // here Dev fee is included here
        ethFeeOnSell = 500;
        firePitFeeOnSell = 0;
        totalFeeOnSell = liquidityFeeOnSell.add(treasuryFeeOnSell).add(insuranceFundFeeOnSell).add(firePitFeeOnSell).add(ethFeeOnSell);

        devAddress = dev;
        devFee = 0;

        _allowedFragments[address(this)][address(router)] = MAX_UINT256;
        pairContract = IPancakePair(pair);

        maxTokenPerWalletPercent = 100; // 1%
        timeframeQuotaInPercentage = 100; // 1%
        timeframeQuotaOutPercentage = 100; // 1%

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[treasuryReceiver] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        initRebaseStartTime = block.timestamp;
        lastRebasedTime = block.timestamp;
        autoRebase = false;
        autoAddLiquidity = true;
        ethRewardEnabled = true;
        
        isFeeExempt[treasuryReceiver] = true;
        isFeeExempt[autoLiquidityReceiver] = true;
        isFeeExempt[insuranceFundReceiver] = true;
        isFeeExempt[firePit] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[dev] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[ZERO] = true;

        distributorGas = 500000;                                                                                          
        rebasePeriod = 15 minutes;
        rebaseRate = 1512;

        emit Transfer(address(0x0), treasuryReceiver, _totalSupply);

        timeframeExpiresAfter = 24 hours;

        maxLPSwapThreshold = _totalSupply.mul(10).div(RESOLUTION);
        maxETHFeeSwapThreshold = _totalSupply.mul(10).div(RESOLUTION);
    }

    function checkTimeframe() internal {
        uint256 _currentTimeStamp1 = block.timestamp;
        if (_currentTimeStamp1 > timeframeCurrent + timeframeExpiresAfter) {
            timeframeCurrent = _currentTimeStamp1;
        }
    }

    function rebase() internal {
        if ( inSwap ) return;

        uint256 _rebaseRate;
        uint256 deltaTimeFromInit = block.timestamp - initRebaseStartTime;
        uint256 deltaTime = block.timestamp - lastRebasedTime;
        uint256 times = deltaTime.div(rebasePeriod);
        uint256 epoch = times.mul(rebasePeriod);

        if (deltaTimeFromInit < (365 days)) {
            _rebaseRate = rebaseRate;
        } else if (deltaTimeFromInit >= (365 days)) {
            _rebaseRate = 211;
        } else if (deltaTimeFromInit >= ((15 * 365 days) / 10)) {
            _rebaseRate = 14;
        } else if (deltaTimeFromInit >= (7 * 365 days)) {
            _rebaseRate = 2;
        }

        uint256 i;
        for (i = 0; i < times; i++) {
            _totalSupply = _totalSupply
                .mul((10**RATE_DECIMALS).add(_rebaseRate))
                .div(10**RATE_DECIMALS);
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        lastRebasedTime = lastRebasedTime.add(times.mul(rebasePeriod));

        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
    }

    function transfer(address to, uint256 value)
        external
        override
        validRecipient(to)
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        
        if (_allowedFragments[from][msg.sender] != MAX_UINT256) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }
        _transferFrom(from, to, value);
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount, "BasicTransfer: Not Enough Balance");
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal whenNotPaused returns (bool) {

        require(!blacklist[sender] && !blacklist[recipient], "Blacklisted");

        if (inSwap || disableAllFee) {
            return _basicTransfer(sender, recipient, amount);
        }

        checkTimeframe();

        inAmounts[timeframeCurrent][recipient] += int256(amount);
        outAmounts[timeframeCurrent][sender] += amount;

        if (!isFeeExempt[recipient] && recipient != pair) {
            // Revert if the receiving wallet exceed the maximum a wallet can hold

            require(
                getMaxTokenPerWallet() >= balanceOf(recipient) + amount,
                "Cannot transfer to this wallet, it would exceed the limit per wallet. [balanceOf > maxTokenPerWallet]"
            );

            // Revert if receiving wallet exceed daily limit
            require(
                getRemainingTransfersIn(recipient) >= 0,
                "Cannot transfer to this wallet for this timeframe, it would exceed the limit per timeframe. [inAmount > timeframeLimit]"
            );
        }

        if (!isFeeExempt[sender] && sender != pair) {
            // Revert if the sending wallet exceed the maximum transfer limit per day
            // We take into calculation the number ever bought of tokens available at this point
            require(
                getRemainingTransfersOut(sender) >= 0,
                "Cannot transfer out from this wallet for this timeframe, it would exceed the limit per timeframe. [outAmount > timeframeLimit]"
            );
        }

        if (shouldRebase()) {
            rebase();
        }

        if (shouldAddLiquidity()) {
            addLiquidity();
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, gonAmount)
            : gonAmount;
			
		if (distributorAddress != address(0) && ethRewardEnabled) {
            try IDividendDistributor(distributorAddress).setShare(sender, _gonBalances[sender].sub(gonAmount, "Dividend: sender balance is not enough").div(_gonsPerFragment)) {} catch {}
            try IDividendDistributor(distributorAddress).setShare(recipient, _gonBalances[recipient].add(gonAmountReceived).div(_gonsPerFragment)) {} catch {}
        }

        if (shouldSwapBack()) {
            swapBack(recipient == pair);
        }

        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount, "_transferFrom: sender balance is not enough");

        _gonBalances[recipient] = _gonBalances[recipient].add(
            gonAmountReceived
        );

        if (distributorAddress != address(0) && ethRewardEnabled) {
            try IDividendDistributor(distributorAddress).process(distributorGas) {} catch {}
        }

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(_gonsPerFragment)
        );
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 gonAmount
    ) internal  returns (uint256) {
        uint256 _liquidityFee;
        uint256 _treasuryFee;
        uint256 _ethFee;
        uint256 _insuranceFundFee;
        uint256 _firePitFee;
        uint256 _totalFee;

        if (recipient == pair) { // sell tax
            _liquidityFee = liquidityFeeOnSell;
            _treasuryFee = treasuryFeeOnSell;
            _ethFee = ethFeeOnSell;
            _insuranceFundFee = insuranceFundFeeOnSell;
            _firePitFee = firePitFeeOnSell;
            _totalFee = totalFeeOnSell;
        } else { // buy tax
            _liquidityFee = liquidityFeeOnBuy;
            _treasuryFee = treasuryFeeOnBuy;
            _ethFee = ethFeeOnBuy;
            _insuranceFundFee = insuranceFundFeeOnBuy;
            _firePitFee = firePitFeeOnBuy;
            _totalFee = totalFeeOnBuy;
        }

        uint256 feeAmount = gonAmount.div(RESOLUTION).mul(_totalFee);
       
        uint256 _firePitFeeAmount = gonAmount.div(RESOLUTION).mul(_firePitFee);
        _gonBalances[firePit] = _gonBalances[firePit].add(_firePitFeeAmount);
        emit Transfer(sender, firePit, _firePitFeeAmount.div(_gonsPerFragment));

        uint256 _thisFee = gonAmount.div(RESOLUTION).mul(_treasuryFee.add(_insuranceFundFee).add(_ethFee));
        _gonBalances[address(this)] = _gonBalances[address(this)].add(_thisFee);
        emit Transfer(sender, address(this), _thisFee.div(_gonsPerFragment));

        uint256 _lpFee = gonAmount.div(RESOLUTION).mul(_liquidityFee);
        _gonBalances[autoLiquidityReceiver] = _gonBalances[autoLiquidityReceiver].add(_lpFee);
        emit Transfer(sender, autoLiquidityReceiver, _lpFee.div(_gonsPerFragment));

        return gonAmount.sub(feeAmount, "fee value exceeds");
    }

    function addLiquidity() internal swapping {
        uint256 autoLiquidityAmount = _gonBalances[autoLiquidityReceiver].div(
            _gonsPerFragment
        );

        if (autoLiquidityAmount < maxLPSwapThreshold || autoLiquidityAmount == 0) return;

        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            _gonBalances[autoLiquidityReceiver]
        );
        _gonBalances[autoLiquidityReceiver] = 0;
        uint256 amountToLiquify = autoLiquidityAmount.div(2);
        uint256 amountToSwap = autoLiquidityAmount.sub(amountToLiquify, "addLiquidity: liquidity balance is not enough");

        if( amountToSwap == 0 ) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETHLiquidity = address(this).balance.sub(balanceBefore, "addLiquidity: ETH balance is not enough");

        if (amountToLiquify > 0 && amountETHLiquidity > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
        }
        lastAddLiquidityTime = block.timestamp;
    }

    function swapBack(bool _isSelling) internal swapping {

        uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);

        if( amountToSwap < maxETHFeeSwapThreshold || amountToSwap == 0) return;

        uint256 balanceBefore = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETHToTreasuryAndSIF = address(this).balance.sub(balanceBefore, "swapBack: ETH balance is not enough");

        uint256 _treasuryFee;
        uint256 _insuranceFundFee;
        uint256 _ethFee;

        if (_isSelling) {
            _treasuryFee = treasuryFeeOnSell;
            _insuranceFundFee = insuranceFundFeeOnSell;
            _ethFee = ethFeeOnSell;
        } else {
            _treasuryFee = treasuryFeeOnBuy;
            _insuranceFundFee = insuranceFundFeeOnBuy;
            _ethFee = ethFeeOnBuy;
        }

        if (!ethRewardEnabled) {
            _ethFee = 0;
        }

        uint256 _denom = _treasuryFee.add(_insuranceFundFee).add(_ethFee);
        uint256 _treasuryFeeValue = amountETHToTreasuryAndSIF.mul(_treasuryFee).div(_denom);

        if (_treasuryFeeValue > 0) {
            (bool success, ) = payable(treasuryReceiver).call{
                value: _treasuryFeeValue,
                gas: 30000
            }("");
            require(success == true, "Error Paying Treasury");
        }
        
        uint256 _totalETHFee = amountETHToTreasuryAndSIF.mul(_ethFee).div(_denom);
        uint256 _insuranceFeeValue = amountETHToTreasuryAndSIF.sub(_treasuryFeeValue).sub(_totalETHFee);

        if (devAddress != address(0) && devFee > 0) {
            uint256 _devFeeValue = amountETHToTreasuryAndSIF.mul(devFee).div(_denom);
            _insuranceFeeValue = _insuranceFeeValue.sub(_devFeeValue, "AWF sub 1 error");

            (bool success, ) = payable(devAddress).call{
                value: _devFeeValue,
                gas: 30000
            }("");
            require(success == true, "Error Paying Dev");
        }

        if (_insuranceFeeValue > 0) {
            (bool success, ) = payable(insuranceFundReceiver).call{
                value: _insuranceFeeValue,
                gas: 30000
            }("");
            require(success == true, "Error Paying Insurance Fund");
        }

        ethRewardStore = ethRewardStore.add(_totalETHFee);

        if (distributorAddress != address(0) && _totalETHFee > 0 && feeToken != address(0)) {
            uint256 beforeAmount = IERC20(feeToken).balanceOf(address(this));
            IPancakeRouter02(router).swapExactETHForTokensSupportingFeeOnTransferTokens{value: _totalETHFee}(
                0,
                feeTokenPath,
                address(this),
                block.timestamp
            );
            uint256 _feeTokenAmount = IERC20(feeToken).balanceOf(address(this)) - beforeAmount;
            IERC20(feeToken).approve(distributorAddress, _feeTokenAmount);
            try IDividendDistributor(distributorAddress).deposit(_feeTokenAmount) {} catch {}
        }
    }

    function withdrawAllToTreasury() external swapping onlyOwner {
        if (address(this).balance > 0) {
            (bool success, ) = payable(treasuryReceiver).call{value: address(this).balance}("");
            require(success, "Unable To Withdraw ETH");
        }

        uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);
        if (amountToSwap > 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                treasuryReceiver,
                block.timestamp
            );
        }
    }

    function shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        return 
            (pair == from && !isFeeExempt[to]) || (pair == to && !isFeeExempt[from]);
    }

    function shouldRebase() internal view returns (bool) {
        return
            autoRebase &&
            (_totalSupply < MAX_SUPPLY) &&
            msg.sender != pair  &&
            !inSwap &&
            block.timestamp >= (lastRebasedTime + rebasePeriod);
    }

    function shouldAddLiquidity() internal view returns (bool) {
        return
            autoAddLiquidity && 
            !inSwap && 
            msg.sender != pair &&
            block.timestamp >= (lastAddLiquidityTime + 2 days);
    }

    function shouldSwapBack() internal view returns (bool) {
        return 
            !inSwap &&
            msg.sender != pair  ; 
    }

    function setAutoRebase(bool _flag) external onlyOwner {
        if (_flag) {
            autoRebase = _flag;
            lastRebasedTime = block.timestamp;
        } else {
            autoRebase = _flag;
        }
    }

    function setAutoAddLiquidity(bool _flag) external onlyOwner {
        if(_flag) {
            autoAddLiquidity = _flag;
            lastAddLiquidityTime = block.timestamp;
        } else {
            autoAddLiquidity = _flag;
        }
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(_gonsPerFragment);
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function manualSync() external {
        IPancakePair(pair).sync();
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _treasuryReceiver,
        address _insuranceFundReceiver,
        address _firePit
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        treasuryReceiver = _treasuryReceiver;
        insuranceFundReceiver = _insuranceFundReceiver;
        firePit = _firePit;

        isFeeExempt[treasuryReceiver] = true;
        isFeeExempt[autoLiquidityReceiver] = true;
        isFeeExempt[insuranceFundReceiver] = true;
        isFeeExempt[firePit] = true;
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        uint256 liquidityBalance = _gonBalances[pair].div(_gonsPerFragment);
        return
            accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }

    function updateFeeExempt(address[] calldata wallets, bool set) external onlyOwner {
        require(wallets.length > 0, "Invalid Parameters");

        uint256 i;
        for (i = 0; i < wallets.length; i ++) {
            isFeeExempt[wallets[i]] = set;
        }
    }

    function setBotBlacklist(address[] calldata botAddresses, bool set) external onlyOwner {
        require(botAddresses.length > 0, "Invalid Parameters");

        uint256 i;
        for (i = 0; i < botAddresses.length; i ++) {
            blacklist[botAddresses[i]] = set;
        }
    }
    
    function setLP(address _address) external onlyOwner {
        pairContract = IPancakePair(_address);
    }
    
    function setFeeTokenPath(address[] calldata _path) external onlyOwner {
        require(_path.length >= 2 && _path[0] == router.WETH());
        feeTokenPath = _path;
        feeToken = _path[_path.length - 1];
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
   
    function balanceOf(address who) public view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    receive() external payable {}

    function getMaxTokenPerWallet() public view returns (uint256) {
        return (_totalSupply * maxTokenPerWalletPercent) / RESOLUTION;
    }

    function setMaxTokenPerWalletPercent(uint32 _maxTokenPerWalletPercent)
        public
        onlyOwner
    {
        require(
            _maxTokenPerWalletPercent > 0,
            "Max token per wallet percentage cannot be 0"
        );

        // Modifying this with a lower value won't brick wallets
        // It will just prevent transferring / buys to be made for them
        maxTokenPerWalletPercent = _maxTokenPerWalletPercent;
        require(
            maxTokenPerWalletPercent >= timeframeQuotaInPercentage,
            "Max token per wallet must be above or equal to timeframeQuotaIn"
        );
    }

    function getTimeframeQuotaIn() public view returns (uint256) {
        return (_totalSupply * timeframeQuotaInPercentage) / RESOLUTION;
    }

    function getTimeframeQuotaOut() public view returns (uint256) {
        return (_totalSupply * timeframeQuotaOutPercentage) / RESOLUTION;
    }

    function getOverviewOf(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            int256,
            int256,
            uint256
        )
    {
        return (
            timeframeCurrent + timeframeExpiresAfter,
            timeframeQuotaInPercentage,
            timeframeQuotaOutPercentage,
            getRemainingTransfersIn(account),
            getRemainingTransfersOut(account),
            block.timestamp
        );
    }

    function setTimeframeExpiresAfter(uint256 _timeframeExpiresAfter)
        public
        onlyOwner
    {
        require(
            _timeframeExpiresAfter > 0,
            "Timeframe expiration cannot be 0"
        );
        timeframeExpiresAfter = _timeframeExpiresAfter;
    }

    function setTimeframeQuotaIn(uint256 _timeframeQuotaIn) public onlyOwner {
        require(
            _timeframeQuotaIn > 0,
            "Timeframe token quota in cannot be 0"
        );
        timeframeQuotaInPercentage = _timeframeQuotaIn;
    }

    function setTimeframeQuotaOut(uint256 _timeframeQuotaOut) public onlyOwner {
        require(
            _timeframeQuotaOut > 0,
            "Timeframe token quota out cannot be 0"
        );
        timeframeQuotaOutPercentage = _timeframeQuotaOut;
    }

    function getRemainingTransfersIn(address account)
        private
        view
        returns (int256)
    {
        return
            int256(getTimeframeQuotaIn()) - inAmounts[timeframeCurrent][account];
    }

    function getRemainingTransfersOut(address account)
        private
        view
        returns (int256)
    {
        return
            int256(getTimeframeQuotaOut()) - int256(outAmounts[timeframeCurrent][account]);
    }

    function setFeePercentagesOnBuy(uint256 _liquidityFee, uint256 _treasuryFee, uint256 _insuranceFundFee, uint256 _ethFee, 
                                uint256 _firePitFee) public onlyOwner {
        liquidityFeeOnBuy = _liquidityFee;
        treasuryFeeOnBuy = _treasuryFee;
        insuranceFundFeeOnBuy = _insuranceFundFee;
        ethFeeOnBuy = _ethFee;
        firePitFeeOnBuy = _firePitFee;
        totalFeeOnBuy = liquidityFeeOnBuy.add(treasuryFeeOnBuy).add(insuranceFundFeeOnBuy).add(ethFeeOnBuy).add(firePitFeeOnBuy);
    }

    function setFeePercentagesOnSell(uint256 _liquidityFee, uint256 _treasuryFee, uint256 _insuranceFundFee, uint256 _ethFee, 
                                uint256 _firePitFee) public onlyOwner {
        liquidityFeeOnSell = _liquidityFee;
        treasuryFeeOnSell = _treasuryFee;
        insuranceFundFeeOnSell = _insuranceFundFee;
        ethFeeOnSell = _ethFee;
        firePitFeeOnSell = _firePitFee;
        totalFeeOnSell = liquidityFeeOnSell.add(treasuryFeeOnSell).add(insuranceFundFeeOnSell).add(ethFeeOnSell).add(firePitFeeOnSell);
    }

    function setSwapThresholdValues(uint256 _LPSwapThreshold, uint256 _ETHSwapThreshold) external onlyOwner {
        maxLPSwapThreshold = _LPSwapThreshold;
        maxETHFeeSwapThreshold = _ETHSwapThreshold;
    }

    function pause(bool _set) external onlyOwner {
        if (_set) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setETHRewardEnabled(bool _set) external onlyOwner {
        ethRewardEnabled = _set;
    }

    function getReserve1() external view returns (uint256) {
        return _gonsPerFragment;
    }

    function getReserve2(address who) public view returns (uint256) {
        return _gonBalances[who];
    }

    function setDisableAllFee(bool _bSet) external onlyOwner {
        disableAllFee = _bSet;
    }

    function setDistributor(address _distributorAddress) external onlyOwner {
        distributorAddress = _distributorAddress;
    }

    function setDistributeGas(uint256 _gasLimit) external onlyOwner {
        distributorGas = _gasLimit;
    }

    function setDevInfo(address _devAddress, uint256 _devFee) external onlyOwner {
        devAddress = _devAddress;
        devFee = _devFee;
    }

    function updateRebaseParams(uint256 _rebasePeriod, uint256 _rebaseRate) external onlyOwner {
        rebasePeriod = _rebasePeriod;
        rebaseRate = _rebaseRate;
    }
}