//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Pair.sol";

/// Insufficient privileges. 
error Forbidden();

/// Invalid Address. 
/// @param addr invalid address.
error InvalidAddress(address addr);

/// Value too large. Maximum `maximum` but `attempt` provided.
/// @param attempt balance available.
/// @param maximum maximum value.
error ValueOverflow(uint256 attempt, uint256 maximum); 

/// Value too large. Maximum `maximum` but `attempt` provided.
/// @param attempt balance available.
/// @param maximum maximum value.
error AllowanceOverflow(uint256 attempt, uint256 maximum); 

/// @title Tales of Elleria: Ellerium ERC20
/// @author Wayne (Ellerian Prince)
/// @notice Tales of Elleria's In-Game Token.
contract ElleriumTokenERC20v2 is Context, IERC20, IERC20Metadata, Ownable {

    /// @dev Mapping from user address to their balances.
    mapping(address => uint256) private _balances;

    /// @dev Mapping from user address to mapping of allowances of each approved address.
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @dev Total Supply of the Token
    uint256 private _totalSupply;

    /// @dev Name of the Token
    string private _name = "Ellerium";

    /// @dev Symbol of the Token
    string private _symbol = "ELM";

    /// @dev Mapping for addresses approved to mint (bridge and LP).
    mapping (address => bool) private _approvedAddresses;

    /// @dev Mints initial sum of Tokens to the deployer for setting up.
    constructor() {
        // 375,550 $ELM allocated into the LP.
        // 500,000 $ELM allocated into team vest (5 years starting 01/01/2023).
        // 125,000 + 175,000 $ELM allocated into TreasureDAO vest. (5 years starting 01/10/2022).
        _mint(_msgSender(), (375550 + 500000 + 300000) * 1e18); 
        _approvedAddresses[_msgSender()] = true;
    }

    /// @dev (Owner Only) Sets approved addresses for custom mechanisms (Token mint from stake/bridge).
    /// @param _address Address affected.
    /// @param _isAllowed Is Approved?
    function setApprovedAddress(address _address, bool _isAllowed) external onlyOwner {
        _approvedAddresses[_address] = _isAllowed;
        emit ApprovedAddressChange(_address, _isAllowed);
    }

    /// @notice Returns the name of the Token.
    /// @return Name of the token.
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @notice Returns the symbol of the Token.
    /// @return Symbol of the token.
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @notice Returns the number of decimals used to get its user representation.
    /// For example, if `decimals` equals `2`, a balance of `505` tokens should
    /// be displayed to a user as `5,05` (`505 / 10 ** 2`).
    /// @return Decimals Used.
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /// @notice Returns the total supply of the Token. See {IERC20-totalSupply}.
    /// @return Total Supply.
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /// @notice Returns the balances of an address. See {IERC20-balanceOf}.
    /// @param account Address to retrieve balances for.
    /// @return Balance of account.
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    
    /// @notice Transfers an amount of tokens to a recipient. See {IERC20-transfer}.
    /// @param recipient Address to receive Tokens.
    /// @param amount Amount of tokens.
    /// @return True if success.
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /// @notice Returns allowances for an address. See {IERC20-allowance}.
    /// @param owner Address with the allowances.
    /// @param spender Address that does the spending.
    /// @return Allowance of the spender for owner.
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    /// @notice Approves allowances for an address. See {IERC20-approve}.
    /// @param spender Address that can spend on sender's behalf.
    /// @param amount Amount to approve for spending.
    /// @return True if success.
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /// @notice See {IERC20-transferFrom}.
    /// Emits an {Approval} event indicating the updated allowance. This is not
    /// required by the EIP. See the note at the beginning of {ERC20}.
    /// @param sender Address sending tokens.
    /// @param recipient Address receiving tokens.
    /// @param amount Amount transferred.
    /// @return True if success.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (amount > currentAllowance) {
            revert AllowanceOverflow(amount, currentAllowance);
        }

        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    /// @notice Atomically increases the allowance granted to `spender` by the caller.
    /// Emits an {Approval} event indicating the updated allowance.
    /// @param spender Address of the spender for the message sender.
    /// @param addedValue Value to add to allowance.
    /// @return True if success.
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /// @notice Atomically decreases the allowance granted to `spender` by the caller.
    /// Emits an {Approval} event indicating the updated allowance.
    /// @param spender Address of the spender for the message sender.
    /// @param subtractedValue Value to decrease from allowance.
    /// @return True if success.
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];

        if (subtractedValue > currentAllowance) {
            revert AllowanceOverflow(subtractedValue, currentAllowance);
        }

        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    /// @notice Moves `amount` of tokens from `sender` to `recipient`.
    /// This internal function is equivalent to {transfer}, with a blacklist function
    /// to prevent bots from swapping tokens automatically after LP is added to. 
    /// Emits a {Transfer} event.
    /// @param sender Address sending tokens.
    /// @param recipient Address receiving tokens.
    /// @param amount Amount transferred.
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        if (sender == address(0)) {
            revert InvalidAddress(sender);
        }

        uint256 senderBalance = _balances[sender];

        if (amount > senderBalance) {
            revert ValueOverflow(amount, senderBalance);
        }

        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        if (recipient == address(0)) {
            // Demint for burn transactions.
            _totalSupply -= amount;    
        } else {
            // Only increment balances for a non-zero address.
            _balances[recipient] += amount;
        }
        
        emit Transfer(sender, recipient, amount);
    }

    /// @notice Creates `amount` tokens and assigns them to `account`, increasing the total supply.
    /// Emits a {Transfer} event.
    /// @param account Address receiving tokens.
    /// @param amount Amount of tokens assigned.
    function _mint(address account, uint256 amount) internal {
        if (account == address(0)) {
            revert InvalidAddress(account);
        }

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    /// @notice (Approved Address Only) Mint Tokens (Bridging/Staking Rewards).
    /// Emits a {Transfer} event.
    /// @param account Address receiving tokens.
    /// @param amount Amount of tokens assigned.
    function mint(address account, uint256 amount) external {
        if (!_approvedAddresses[_msgSender()]) {
            revert InvalidAddress(_msgSender());
        }

        _mint(account, amount);
    }

    /// @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
    /// This internal function is equivalent to `approve`, and can be used to
    /// e.g. set automatic allowances for certain subsystems, etc.
    /// Emits an {Approval} event.
    /// @param owner Address with the allowances. Cannot be the zero address.
    /// @param spender Address that will be spending on owner's behalf. Cannot be the zero address.
    /// @param amount Amount to approve for spending.
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if (owner == address(0) || spender == address(0)) {
            revert InvalidAddress(address(0));
        }

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  /// @notice Event emitted when an address' blacklist status changes.
  /// @param addr The address affected.
  /// @param isBlacklisted Is blacklisted?
  event Blacklist(address addr, bool isBlacklisted);

  /// @notice Event emitted when an approved address' status changes.
  /// @param addr The address affected.
  /// @param isApproved Is approved?
  event ApprovedAddressChange(address addr, bool isApproved);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
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