/**
 *Submitted for verification at Arbiscan on 2023-06-15
*/

/**

 *Welcome brave on-chain explorers please join us on our quest
 *into the center of our retro active wormhole...
 *We never left nor shall we ever leave we are here with you
 *givang our autistic brains cells retard food by staring at yet another
 *shitcoin chart that will be just like all the other pnd  tokens ever.

 ** But what if you could short it?

*Call the payable function openShort() with the amount of ETH you wish to put as your short collateral;
*Call the function closeShort() to close your position and receive your collateral +/- profit/loss;
*You can check you liquidation price by consulting the shortPositions[address] mapping;


*The only communication for now will be through explorer to avoid the noise and jeets from tg
*A private chat will be set up with the ones that know how to reach!


*This is a L2 testrun our initial protocol experiment a retard experiment to he
*Please use this contract with Caution and with funds that mean absolutely nothing to you!
*This token is for pure entertainement and learning purposes for better implementation in terms of gas effeciency
*Not even our final form yet!
*Help us with our live stress testing of our contract!
*
*All the interactions with our contract will be considered for mainnet launch

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function allPairsLength() external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

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
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
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

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address from) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

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
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
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
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);
}

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

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
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
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
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
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
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
    function transferFrom(address from, address to, uint256 amount) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

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
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
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

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }
}

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
contract ARBITRUM is ERC20, Ownable, ReentrancyGuard {
    // TOKENOMICS START ==========================================================>
    string private _name = "UgandaKnucklesTrumpPepeInu.v69";
    string private _symbol = "ARBITRUM";
    uint8 private _decimals = 18;
    uint256 private _supply = 69420;
    uint256 private _liqSupply = 42069;
    uint256 public taxForLiquidity = 47; //sniper protection, to be lowered to 1% after launch
    uint256 public taxForMarketing = 47; //sniper protection, to be lowered to 2% after launch
    uint256 public taxForShort = 47;
    uint256 public maxTxAmount = 69 * 10 ** _decimals;
    uint256 public maxWalletAmount = 690 * 10 ** _decimals;
    address public _treasuryWallet = 0x019e913C548ded21C083D8C7a87300442a377dBE;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public _treasuryReserves = 0;
    uint256 public minShort = 0.01 ether;
    uint256 public maxShort = 2 ether;
    uint256 public maxShorters = 108;
    uint256 public maxLoanTime = 1 hours;
    uint256 public margin = 93;
    bool public autoLiquidate = true;
    bool public swapLiquidations = false;
    bool public liqAdded = false;
    mapping(address => bool) public _isExcludedFromFee;

    uint256 public numTokensSellToAddToLiquidity = 333 * 10 ** _decimals;
    uint256 public numTokensSellToAddToETH = 333 * 10 ** _decimals;
    mapping(address => ShortPosition) public shortPositions;
    mapping(address => uint256) public addressIndex;
    address[] public shortHolders;

    function postLaunch() external onlyOwner {
        taxForLiquidity = 3;
        taxForMarketing = 2;
        maxTxAmount = 69000 * 10 ** _decimals;
        maxWalletAmount = 69000 * 10 ** _decimals;
    }

    event ShortOpened(address _address, uint256 CollateralAmount, uint256 borrowedTokens, uint256 liqPrice);
    event ShortClosed(address _address, uint256 profit, uint256 ETHbuyBack);
    event Liquidated(address _address, uint256 CollateralAmount, uint256 liqPrice);
    event ExcludedFromFeeUpdated(address _address, bool _status);
    event PairUpdated(address _address);

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    struct ShortPosition {
        uint256 amountBorrowed;
        uint256 collateralValue;
        uint256 openTime;
        uint256 tokenPrice;
        uint256 liquidationPrice;
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() ERC20(_name, _symbol) {
        _mint(address(this), (_supply * 10 ** _decimals));

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); //eth mainnet
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _supply * 10 ** _decimals);

        _isExcludedFromFee[address(uniswapV2Router)] = true;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[treasuryWallet] = true;
    }

    function updatePair(address _pair) external onlyOwner {
        require(_pair != DEAD, "LP Pair cannot be the Dead wallet, or 0!");
        require(_pair != address(0), "LP Pair cannot be the Dead wallet, or 0!");
        uniswapV2Pair = _pair;
        emit PairUpdated(_pair);
    }

    function excludeFromFee(address _address, bool _status) external onlyOwner {
        _isExcludedFromFee[_address] = _status;
        emit ExcludedFromFeeUpdated(_address, _status);
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
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");
         if (autoLiquidate) liquidateAll();

        if ((from == uniswapV2Pair || to == uniswapV2Pair) && !inSwapAndLiquify && liqAdded) {
            if (from != uniswapV2Pair) {
                uint256 contractLiquidityBalance = balanceOf(address(this)) - _treasuryReserves;
                if (
                    contractLiquidityBalance >= numTokensSellToAddToLiquidity && amount >= numTokensSellToAddToLiquidity
                ) {
                    _swapAndLiquify(numTokensSellToAddToLiquidity);
                }
                if ((_treasuryReserves) >= numTokensSellToAddToETH && amount >= numTokensSellToAddToETH) {
                    uint256 initialBalance = address(this).balance;
                    _swapTokensForEth(numTokensSellToAddToETH);
                    _treasuryReserves -= numTokensSellToAddToETH;
                    uint256 newBalance = (address(this).balance - initialBalance);
                    bool sent = payable(treasuryWallet).send(newBalance);
                    require(sent, "Failed to send ETH");
                }
            }

            uint256 transferAmount;
            if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || (from != uniswapV2Pair && to != uniswapV2Pair)) {
                transferAmount = amount;
            } else {
                require(amount <= maxTxAmount, "ERC20: transfer amount exceeds the max transaction amount");
                if (from == uniswapV2Pair) {
                    require(
                        (amount + balanceOf(to)) <= maxWalletAmount,
                        "ERC20: balance amount exceeded max wallet amount limit"
                    );
                }

                uint256 marketingShare = ((amount * taxForMarketing) / 100);
                uint256 liquidityShare = ((amount * taxForLiquidity) / 100);
                transferAmount = amount - (marketingShare + liquidityShare);
                _treasuryReserves += marketingShare;

                super._transfer(from, address(this), (marketingShare + liquidityShare));
            }
            super._transfer(from, to, transferAmount);
        } else {
            super._transfer(from, to, amount);
        }
       
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = (contractTokenBalance / 2);
        uint256 otherHalf = (contractTokenBalance - half);

        uint256 initialBalance = address(this).balance;

        _swapTokensForEth(half);

        uint256 newBalance = (address(this).balance - initialBalance);

        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
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
    }

    function _swapEthForTokens(uint256 ETHAmount) private lockTheSwap {
        address[] memory path = new address[](2);

        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ETHAmount}(
            0,
            path,
            treasuryWallet,
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private lockTheSwap {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            treasuryWallet,
            block.timestamp
        );
    }

    function changemarketingWallet(address newWallet) public onlyOwner returns (bool) {
        require(newWallet != DEAD, "LP Pair cannot be the Dead wallet, or 0!");
        require(newWallet != address(0), "LP Pair cannot be the Dead wallet, or 0!");
        treasuryWallet = newWallet;
        return true;
    }

    function gottagofast() external onlyOwner {
        uint256 LiqTokenAmount = _liqSupply * 10 ** _decimals;
        _approve(address(this), address(uniswapV2Router), _supply * 10 ** _decimals);

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            LiqTokenAmount,
            0,
            0,
            owner(),
            type(uint).max
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        liqAdded = true;
    }

    function changeTaxForLiquidityAndMarketing(
        uint256 _taxForLiquidity,
        uint256 _taxForMarketing,
        uint256 _taxForShort
    ) public onlyOwner returns (bool) {
        require((_taxForLiquidity + _taxForMarketing) <= 10, "ERC20: total tax must not be greater than 10%");
        taxForLiquidity = _taxForLiquidity;
        taxForMarketing = _taxForMarketing;
        taxForShort = _taxForShort;

        return true;
    }

    function changeSwapThresholds(
        uint256 _numTokensSellToAddToLiquidity,
        uint256 _numTokensSellToAddToETH
    ) public onlyOwner returns (bool) {
        require(_numTokensSellToAddToLiquidity < _supply / 98, "Cannot liquidate more than 2% of the supply at once!");
        require(_numTokensSellToAddToETH < _supply / 98, "Cannot liquidate more than 2% of the supply at once!");
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity * 10 ** _decimals;
        numTokensSellToAddToETH = _numTokensSellToAddToETH * 10 ** _decimals;

        return true;
    }

    function changeMaxTxAmount(uint256 _maxTxAmount) public onlyOwner returns (bool) {
        maxTxAmount = _maxTxAmount;

        return true;
    }

    function changeAutoLiquidate(bool _autoliq, bool _swapLiquidations) public onlyOwner returns (bool) {
        autoLiquidate = _autoliq;
        swapLiquidations = _swapLiquidations;

        return true;
    }

    function changeMaxWalletAmount(uint256 _maxWalletAmount) public onlyOwner returns (bool) {
        maxWalletAmount = _maxWalletAmount;

        return true;
    }

    function changeShortConstants(
        uint256 _minShort,
        uint256 _maxShort,
        uint256 _maxShorters,
        uint256 _maxLoanTime,
        uint256 _margin
    ) public onlyOwner returns (bool) {
        minShort = _minShort;
        maxShort = _maxShort;
        maxShorters = _maxShorters;
        maxLoanTime = _maxLoanTime;
        margin = _margin;
        return true;
    }


    function TokenPrice() public view returns (uint256) {
        address[] memory path = new address[](2);
        uint256 zeroUsd = 0;

        path[0] = address(this);

        path[1] = uniswapV2Router.WETH();

        try uniswapV2Router.getAmountsOut(1 * 10 ** 18, path) returns (uint[] memory amounts) {
            return amounts[1];
        } catch {
            return zeroUsd;
        }
    }

    function TokensForETH(uint256 ETHamount) public view returns (uint256) {
        address[] memory path = new address[](2);
        uint256 zeroUsd = 0;
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        try uniswapV2Router.getAmountsOut(ETHamount, path) returns (uint[] memory amounts) {
            return amounts[1];
        } catch {
            return zeroUsd;
        }
    }

    function openShort() public payable nonReentrant {
        uint256 tokenPrice = TokenPrice();
        uint256 collateralValue = msg.value;
        uint256 amountBorrowed = TokensForETH(collateralValue);
        uint256 amountSold = (amountBorrowed * margin) / 100;

        require(amountBorrowed <= balanceOf(address(this)), "No more tokens to lend");
        require(shortHolders.length < maxShorters, "No more shorting spaces");
        require(shortPositions[msg.sender].collateralValue == 0, "Address has Open Short");
        require(msg.value >= minShort, "minimum Short not met");
        require(msg.value <= maxShort, "maximum Short exceded");

        // _addLiquidity(amountBorrowed, collateralValue);

        _swapTokensForEth(amountBorrowed);
        tokenPrice = TokenPrice();
        uint256 liquidationPrice = (tokenPrice * (100 + margin)) / 100;
        // Insert the new address into the shortHolders array in sorted order

        uint256 i = shortHolders.length;
        shortHolders.push(msg.sender);

        while (i > 0 && shortPositions[shortHolders[i - 1]].liquidationPrice > liquidationPrice) {
            shortHolders[i] = shortHolders[i - 1];
            addressIndex[shortHolders[i]] = i;
            i--;
        }
        shortHolders[i] = msg.sender;
        addressIndex[msg.sender] = i;
        shortPositions[msg.sender] = ShortPosition(
            amountBorrowed,
            collateralValue,
            block.timestamp,
            tokenPrice,
            liquidationPrice
        );
        emit ShortOpened(msg.sender, collateralValue, amountBorrowed, liquidationPrice);
    }

    function calcProfit(address user) public view returns (uint256) {
        uint256 currTokenPrice = TokenPrice();
        uint256 opentokenPrice = shortPositions[user].tokenPrice;
        uint256 collateralValue = shortPositions[user].collateralValue;

        uint256 profitRatio = (100 * opentokenPrice) / currTokenPrice;
        uint256 remainingCollateral = (collateralValue * profitRatio) / 100;

        return remainingCollateral;
    }

    function calcInterest(address user) public view returns (uint256) {
        uint256 currTimeStamp = block.timestamp;
        uint256 openTime = shortPositions[user].openTime;
        uint256 duration = currTimeStamp - openTime;
        uint256 interest = (100 * duration) / maxLoanTime;

        return interest;
    }

    function calcDuration(address user) public view returns (uint256) {
        uint256 currTimeStamp = block.timestamp;
        uint256 openTime = shortPositions[user].openTime;
        uint256 duration = currTimeStamp - openTime;

        return duration;
    }

    address public treasuryWallet = 0x019e913C548ded21C083D8C7a87300442a377dBE;

    function triggerTreasuryBuyback(uint256 amount) external onlyOwner {
        _swapEthForTokens(amount);
    }

    function closeShort() public nonReentrant {
        uint256 closeTokenPrice = TokenPrice();
        uint256 liqPrice = shortPositions[msg.sender].liquidationPrice;
        require(shortPositions[msg.sender].collateralValue > 0, "No Open Short");
        require(closeTokenPrice < liqPrice, "YOU BEEN LIQUIDATED");

        uint256 amountBorrowed = shortPositions[msg.sender].amountBorrowed;
        uint256 loanDuration = calcDuration(msg.sender);
        //    uint buybackmargin= (100+ slipage)/100;

        uint256 amountETHrepay = (closeTokenPrice * amountBorrowed) / (10 ** _decimals);
        uint256 profit = calcProfit(msg.sender);

        uint256 interestFee = (taxForShort * profit * loanDuration) / (100 * maxLoanTime);
        uint256 userFunds = profit - interestFee;

        _swapEthForTokens(amountETHrepay);

        if (userFunds > 0 && userFunds < address(this).balance) {
            bool sentuser = payable(msg.sender).send(userFunds);
            require(sentuser, "Failed to send ETH");
        }
        if (interestFee > 0 && interestFee < address(this).balance) {
            bool sent = payable(treasuryWallet).send(interestFee);

            require(sent, "Failed to send ETH");
        }
        emit ShortClosed(msg.sender, userFunds, amountETHrepay);
        delete shortPositions[msg.sender];

        //  Remove the address from the shortHolders array
        for (uint j = addressIndex[msg.sender]; j < shortHolders.length - 1; j++) {
            shortHolders[j] = shortHolders[j + 1];
        }
        shortHolders.pop();
        delete addressIndex[msg.sender];
    }

    function liquidateAll() public {
        uint256 currentTokenPrice = TokenPrice();
        uint256 length = shortHolders.length;
        if(length==0)
        return;

        // Iterate over shortHolders array
        for (uint256 i = 0; i < length; i++) {
            // Get the short position for the current holder
            ShortPosition storage position = shortPositions[shortHolders[0]];

            // If the current token price is above the liquidation price, liquidate the position
            if (currentTokenPrice > position.liquidationPrice) {
                uint256 amountETHrepay = (position.collateralValue * margin) / 100;
                // Add any necessary liquidation logic here, such as transferring the collateral
                if (swapLiquidations) _swapEthForTokens(amountETHrepay);

                emit Liquidated(shortHolders[0], position.collateralValue, position.liquidationPrice);
                // Remove the position from the shortPositions mapping
                delete shortPositions[shortHolders[0]];

                // Remove the address from the shortHolders array
                if (shortHolders.length > 1)
                    for (uint j = i; j < shortHolders.length - 1; j++) {
                        shortHolders[j] = shortHolders[j + 1];
                    }
                shortHolders.pop();

                length--;
            } else {
                // As the array is sorted, we can stop the loop once we find a position that doesn't meet the criteria
                break;
            }
        }
    }

    function liquidateUser(address user) public {
        uint256 currentTokenPrice = TokenPrice();
        uint256 index = addressIndex[user];

        // Iterate over shortHolders array

        // Get the short position for the current holder
        ShortPosition storage position = shortPositions[user];

        // If the current token price is above the liquidation price, liquidate the position
        if (currentTokenPrice > position.liquidationPrice) {
            uint256 amountETHrepay = (position.collateralValue * margin) / 100;
            // Add any necessary liquidation logic here, such as transferring the collateral

            if (swapLiquidations) _swapEthForTokens(amountETHrepay);

            emit Liquidated(shortHolders[index], position.collateralValue, position.liquidationPrice);
            // Remove the position from the shortPositions mapping
            delete shortPositions[shortHolders[index]];

            // Remove the address from the shortHolders array
            for (uint j = index; j < shortHolders.length - 1; j++) {
                shortHolders[j] = shortHolders[j + 1];
            }
            shortHolders.pop();
        }
    }

    function somethingAboutTokens(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    function EmergencyFundRecovery() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }

    receive() external payable {}
}