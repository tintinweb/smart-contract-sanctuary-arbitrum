// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ==========================================================
// ====================== UniswapAMM ========================
// ==========================================================

// Primary Author(s)
// MAXOS Team: https://maxos.finance/

import "../Common/Owned.sol";
import "../Utils/Uniswap/V3/ISwapRouter.sol";
import "../Utils/Uniswap/V3/libraries/TransferHelper.sol";

contract UniswapAMM is Owned {
    // Uniswap v3
    ISwapRouter public constant uniV3Router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    constructor(address _sweep_address) 
        Owned(_sweep_address)
    {}

    event Bought(uint256 usdx_amount);
    event Sold(uint256 sweep_amount);

    /* ========== Actions ========== */

    /**
     * @notice Buy Sweep
     * @param _collateral_address Token Address to use for buying sweep.
     * @param _collateral_amount Token Amount.
     * @param _amountOutMin Minimum amount out.
     * @dev Increases the sweep balance and decrease collateral balance.
     */
    function buySweep(
        address _collateral_address,
        uint256 _collateral_amount,
        uint256 _amountOutMin
    ) public returns (uint256 sweep_amount) {
        sweep_amount = swapExactInput(
            _collateral_address,
            sweep_address,
            _collateral_amount,
            _amountOutMin
        );

        emit Bought(sweep_amount);
    }

    /**
     * @notice Sell Sweep
     * @param _collateral_address Token Address to return after selling sweep.
     * @param _sweep_amount Sweep Amount.
     * @param _amountOutMin Minimum amount out.
     * @dev Decreases the sweep balance and increase collateral balance
     */
    function sellSweep(
        address _collateral_address,
        uint256 _sweep_amount,
        uint256 _amountOutMin
    ) public returns (uint256 collateral_amount) {
        collateral_amount = swapExactInput(
            address(SWEEP),
            _collateral_address,
            _sweep_amount,
            _amountOutMin
        );

        emit Sold(_sweep_amount);
    }

    /**
     * @notice Swap tokenA into tokenB using uniV3Router.ExactInputSingle()
     * @param _tokenA Address to in
     * @param _tokenB Address to out
     * @param _amountIn Amount of _tokenA
     * @param _amountOutMin Minimum amount out.
     */
    function swapExactInput(
        address _tokenA,
        address _tokenB,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) public returns (uint256 amountOut) {
        // Approval
        TransferHelper.safeTransferFrom(
            _tokenA,
            msg.sender,
            address(this),
            _amountIn
        );
        TransferHelper.safeApprove(_tokenA, address(uniV3Router), _amountIn);

        ISwapRouter.ExactInputSingleParams memory swap_params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenA,
                tokenOut: _tokenB,
                fee: 3000,
                recipient: msg.sender,
                deadline: block.timestamp + 200,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMin,
                sqrtPriceLimitX96: 0
            });

        amountOut = uniV3Router.exactInputSingle(swap_params);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// Primary Author(s)
// MAXOS Team: https://maxos.finance/

interface IAsset {
    function currentValue() external view returns (uint256);

    function deposit(uint256 usdx_amount, uint256 sweep_amount) external;

    function withdraw(uint256 amount) external;

    function updateValue(uint256 value) external;

    function withdrawRewards(address to) external;

    function liquidate(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity 0.8.16;

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)
pragma solidity 0.8.16;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "../Context.sol";

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
pragma solidity 0.8.16;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
pragma solidity 0.8.16;

import "./IERC20.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

// ==========================================================
// ====================== Owned ========================
// ==========================================================

// Primary Author(s)
// MAXOS Team: https://maxos.finance/

import "../Sweep/ISweep.sol";

contract Owned {
    address public sweep_address;
    ISweep public SWEEP;

    // Events
    event SetSweep(address indexed sweep_address);

    // Errors
    error OnlyAdmin();
    error OnlyCollateralAgent();
    error ZeroAddressDetected();

    constructor(address _sweep_address) {
        sweep_address = _sweep_address;
        SWEEP = ISweep(_sweep_address);
    }

    modifier onlyAdmin() {
        if (msg.sender != SWEEP.owner()) revert OnlyAdmin();
        _;
    }

    modifier onlyCollateralAgent() {
        if (msg.sender != SWEEP.collateral_agency())
            revert OnlyCollateralAgent();
        _;
    }

    /**
     * @notice setSweep
     * @param _sweep_address.
     */
    function setSweep(address _sweep_address) external onlyAdmin {
        if (_sweep_address == address(0)) revert ZeroAddressDetected();
        sweep_address = _sweep_address;
        SWEEP = ISweep(_sweep_address);

        emit SetSweep(_sweep_address);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.16;

interface IStabilizer {
    // Getters
    function sweep_borrowed() external view returns (uint256);

    function min_equity_ratio() external view returns (int256);

    function loan_limit() external view returns (uint256);

    function call_time() external view returns (uint256);

    function call_delay() external view returns (uint256);

    function call_amount() external view returns (uint256);

    function borrower() external view returns (address);

    function settings_enabled() external view returns (bool);

    function spread_fee() external view returns (uint256);

    function spread_date() external view returns (uint256);

    function liquidator_discount() external view returns (uint256);

    function liquidatable() external view returns (bool);

    function frozen() external view returns (bool);

    function isDefaulted() external view returns (bool);

    function getCurrentValue() external view returns (uint256);
    
    function getDebt() external view returns (uint256);

    function accruedFee() external view returns (uint256);

    function getJuniorTrancheValue() external view returns (int256);

    function getEquityRatio() external view returns (int256);

    // Setters
    function configure(
        address asset,
        int256 min_equity_ratio,
        uint256 spread_fee,
        uint256 loan_limit,
        uint256 liquidator_discount,
        uint256 call_delay,
        bool liquidatable,
        string calldata link
    ) external;

    function propose() external;

    function reject() external;

    function setFrozen(bool frozen) external;

    function setBorrower(address borrower) external;

    // Actions
    function invest(uint256 amount0, uint256 amount1) external;

    function divest(uint256 usdx_amount) external;

    function buySWEEP(uint256 usdx_amount) external;

    function sellSWEEP(uint256 sweep_amount) external;

    function buy(uint256 usdx_amount, uint256 amount_out_min)
        external
        returns (uint256);

    function sell(uint256 sweep_amount, uint256 amount_out_min)
        external
        returns (uint256);

    function borrow(uint256 sweep_amount) external;

    function repay(uint256 sweep_amount) external;

    function withdraw(address token, uint256 amount) external;

    function collect() external;

    function payFee() external;

    function liquidate() external;

    function marginCall(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma experimental ABIEncoderV2;

// ====================================================================
// ====================== Stabilizer.sol ==============================
// ====================================================================

// Primary Author(s)
// MAXOS Team: https://maxos.finance/

import "./IStabilizer.sol";
import "../Sweep/ISweep.sol";
import "../Assets/IAsset.sol";
import "../AMM/UniswapAMM.sol";
import "../Common/ERC20/ERC20.sol";
import "../Utils/Uniswap/V3/libraries/TransferHelper.sol";

/**
 * @title Stabilizer
 * @author MAXOS Team - https://maxos.finance/
 * @dev Implementation:
 * Facilitates the investment and paybacks of off-chain & on-chain assets
 * Allows to deposit and withdraw usdx
 * Allows to take debt by minting sweep and repaying by burning sweep
 * Allows to buy and sell sweep in an AMM
 * Repayments made by burning sweep
 * EquityRatio = Junior / (Junior + Senior)
 * Requires that the EquityRatio > MinimumEquityRatio when:
 * minting => increase of the senior tranche
 * withdrawing => decrease of the junior tranche
 */
contract Stabilizer is IStabilizer {
    // Variables
    address public borrower;
    int256 public min_equity_ratio; // Minimum Equity Ratio. 10000 is 1%
    uint256 public sweep_borrowed;
    uint256 public loan_limit;

    uint256 public call_time;
    uint256 public call_delay;
    uint256 public call_amount;

    uint256 public spread_fee; // 10000 is 1%
    uint256 public spread_date;
    uint256 public liquidator_discount; // 10000 is 1%
    bool public liquidatable;
    string public link;

    bool public settings_enabled;
    bool public frozen;

    // Investment Asset
    IAsset public asset;
    UniswapAMM public amm;

    // Tokens
    ISweep public sweep;
    ERC20 public usdx;

    // Constants for various precisions
    uint256 private constant DAY_SECONDS = 60 * 60 * 24; // seconds of Day
    uint256 private constant TIME_ONE_YEAR = 365 * DAY_SECONDS; // seconds of Year
    uint256 private constant PRECISION = 1e6;

    /* ========== Events ========== */

    event Borrowed(uint256 indexed sweep_amount);
    event Invested(uint256 indexed usdx_amount, uint256 indexed sweep_amount);
    event Divested(uint256 indexed amount);
    event Repaid(uint256 indexed sweep_amount);
    event Withdrawn(address indexed token, uint256 indexed amount);
    event Collected(address indexed owner);
    event PayFee(uint256 indexed sweep_amount);
    event Liquidated(address indexed user);
    event Bought(uint256 indexed sweep_amount);
    event Sold(uint256 indexed sweep_amount);
    event BoughtSWEEP(uint256 indexed sweep_amount);
    event SoldSWEEP(uint256 indexed usdx_amount);
    event FrozenChanged(bool indexed frozen);
    event BorrowerChanged(address indexed borrower);
    event Proposed(address indexed borrower);
    event Rejected(address indexed borrower);
    event LoanLimitChanged(uint256 indexed loan_limit);
    event ConfigurationChanged(
        address indexed asset,
        int256 indexed min_equity_ratio,
        uint256 indexed spread_fee,
        uint256 loan_limit,
        uint256 liquidator_discount,
        uint256 call_delay,
        bool liquidatable,
        string url_link
    );

    /* ========== Errors ========== */

    error StabilizerFrozen();
    error OnlyBorrower();
    error OnlyBalancer();
    error OnlyAdmin();
    error SettingsDisabled();
    error ZeroAddressDetected();
    error OverZero();
    error InvalidMinter();
    error NotEnoughBalance();
    error EquityRatioExcessed();
    error InvalidToken();
    error NotDefaulted();
    error SpreadNotEnough();
    error NotValidAddress();
    error AssetNotLiquidatable();

    /* ========== Modifies ========== */

    modifier notFrozen() {
        if (frozen) revert StabilizerFrozen();
        _;
    }

    modifier onlyBorrower() {
        if (msg.sender != borrower) revert OnlyBorrower();
        _;
    }

    modifier onlyBalancer() {
        if (msg.sender != sweep.balancer()) revert OnlyBalancer();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != sweep.owner()) revert OnlyAdmin();
        _;
    }

    modifier onlySettingsEnabled() {
        if (!settings_enabled) revert SettingsDisabled();
        _;
    }

    modifier validAddress(address _addr) {
        if (_addr == address(0)) revert ZeroAddressDetected();
        _;
    }

    modifier validAmount(uint256 _amount) {
        if (_amount == 0) revert OverZero();
        _;
    }

    constructor(
        address _sweep_address,
        address _usdx_address,
        address _amm_address,
        int256 _min_equity_ratio,
        uint256 _spread_fee
    ) {
        sweep = ISweep(_sweep_address);
        usdx = ERC20(_usdx_address);
        amm = UniswapAMM(_amm_address);
        borrower = sweep.owner();
        min_equity_ratio = _min_equity_ratio;
        spread_fee = _spread_fee;
        settings_enabled = true;
        frozen = false;
    }

    /* ========== Views ========== */

    /**
     * @notice Get Junior Tranche Value
     * @return int256 calculated junior tranche amount.
     */
    function getJuniorTrancheValue() external view returns (int256) {
        uint256 senior_tranche_in_usdx = sweep.convertToUSDX(sweep_borrowed);
        uint256 total_value = getCurrentValue();

        return int256(total_value) - int256(senior_tranche_in_usdx);
    }

    /**
     * @notice Get Debt Amount
     * debt = borrow_amount + spread fee
     * @return uint256 calculated debt amount.
     */
    function getDebt() public view returns (uint256) {
        return sweep_borrowed + accruedFee();
    }

    /**
     * @notice Defaulted
     * @return bool that tells if stabilizer is in default.
     */
    function isDefaulted() public view returns (bool) {
        return
            (call_amount > 0 && block.timestamp > call_time) ||
            (getEquityRatio() < min_equity_ratio);
    }

    /**
     * @notice Get Equity Ratio
     * @return the current equity ratio based in the internal storage.
     * @dev this value have a precision of 6 decimals.
     */
    function getEquityRatio() public view returns (int256) {
        return calculateEquityRatio(0, 0);
    }

    /**
     * @notice Get Spread Amount
     * fee = borrow_amount * spread_ratio * (time / time_per_year)
     * @return uint256 calculated spread amount.
     */
    function accruedFee() public view returns (uint256) {
        if (sweep_borrowed == 0) return 0;
        else {
            uint256 period = block.timestamp - spread_date;
            return
                (((sweep_borrowed * spread_fee) / PRECISION) * period) /
                TIME_ONE_YEAR;
        }
    }

    /**
     * @notice Get Current Value
     * @return uint256.
     */
    function getCurrentValue() public view returns (uint256) {
        if (address(asset) == address(0)) return 0;
        uint256 usdx_balance = usdx.balanceOf(address(this));
        uint256 sweep_balance = sweep.balanceOf(address(this));
        uint256 sweep_balance_in_usdx = sweep.convertToUSDX(sweep_balance);

        return asset.currentValue() + usdx_balance + sweep_balance_in_usdx;
    }

    /* ========== Settings ========== */

    /**
     * @notice Set Borrower - who manages the investment actions.
     * @param _borrower.
     */
    function setBorrower(address _borrower)
        external
        onlyAdmin
        validAddress(_borrower)
    {
        borrower = _borrower;
        settings_enabled = true;

        emit BorrowerChanged(_borrower);
    }

    /**
     * @notice Frozen - stops investment actions.
     * @param _frozen.
     */
    function setFrozen(bool _frozen) external onlyAdmin {
        frozen = _frozen;

        emit FrozenChanged(_frozen);
    }

    /**
     * @notice Margin Call.
     * @param _usdx_call_amount to swap for Sweep.
     */
    function marginCall(uint256 _usdx_call_amount)
        external
        onlyBalancer
        validAmount(_usdx_call_amount)
    {
        uint256 amount_to_redeem = 0;
        uint256 missing_usdx = 0;

        uint256 sweep_to_buy = sweep.convertToSWEEP(_usdx_call_amount);
        uint256 usdx_balance = usdx.balanceOf(address(this));
        uint256 sweep_balance = sweep.balanceOf(address(this));

        call_time = block.timestamp + call_delay;
        call_amount = _min(sweep_to_buy, sweep_borrowed);
        
        if(sweep_balance < call_amount) {
            uint256 missing_sweep = call_amount - sweep_balance;
            missing_usdx = sweep.convertToUSDX(missing_sweep);

            amount_to_redeem = (missing_usdx > usdx_balance) ?
                (missing_usdx - usdx_balance) : 0;
        }

        if(liquidatable && amount_to_redeem > 0) asset.withdraw(amount_to_redeem);

        usdx_balance = usdx.balanceOf(address(this));
        uint256 amount_to_buy = _min(usdx_balance, missing_usdx);
        if(amount_to_buy > 0) _buy(amount_to_buy, 0);

        sweep_balance = sweep.balanceOf(address(this));
        uint256 sweep_to_repay = _min(call_amount, sweep_balance);
        if(sweep_to_repay > 0) _repay(sweep_to_repay);
    }

    /**
     * @notice Configure intial settings
     * @param _asset Address of a Asset
     * @param _min_equity_ratio The minimum equity ratio can be negative.
     * @param _spread_fee.
     * @param _loan_limit.
     * @param _link Url link.
     */
    function configure(
        address _asset,
        int256 _min_equity_ratio,
        uint256 _spread_fee,
        uint256 _loan_limit,
        uint256 _liquidator_discount,
        uint256 _call_delay,
        bool _liquidatable,
        string calldata _link
    ) external onlyBorrower onlySettingsEnabled validAddress(_asset) {
        asset = IAsset(_asset);
        min_equity_ratio = _min_equity_ratio;
        spread_fee = _spread_fee;
        loan_limit = _loan_limit;
        liquidator_discount = _liquidator_discount;
        link = _link;
        call_delay = _call_delay;
        liquidatable = _liquidatable;

        emit ConfigurationChanged(
            _asset,
            _min_equity_ratio,
            _spread_fee,
            _loan_limit,
            _liquidator_discount,
            _call_delay,
            _liquidatable,
            _link
        );
    }

    /**
     * @notice Changes the account that control the global configuration to the protocol/governance admin
     * @dev after disable settings by admin
     * the protocol will evaluate adding the stabilizer to the minter list.
     */
    function propose() external onlyBorrower {
        settings_enabled = false;

        emit Proposed(borrower);
    }

    /**
     * @notice Changes the account that control the global configuration to the borrower
     * @dev after enable settings for the borrower
     * he/she should edit the values to align to the protocol requirements
     */
    function reject() external onlyAdmin {
        settings_enabled = true;

        emit Rejected(borrower);
    }

    /* ========== Actions ========== */

    /**
     * @notice Borrows Sweep
     * Asks the stabilizer to mint a certain amount of sweep token.
     * @param _sweep_amount.
     * @dev Increases the sweep_borrowed (senior tranche).
     */
    function borrow(uint256 _sweep_amount)
        external
        onlyBorrower
        notFrozen
        validAmount(_sweep_amount)
    {
        if (!sweep.isValidMinter(address(this))) revert InvalidMinter();

        int256 current_equity_ratio = calculateEquityRatio(_sweep_amount, 0);
        if (current_equity_ratio < min_equity_ratio)
            revert EquityRatioExcessed();

        _payFee();
        sweep.minter_mint(address(this), _sweep_amount);
        sweep_borrowed += _sweep_amount;

        emit Borrowed(_sweep_amount);
    }

    /**
     * @notice Repays Sweep
     * Burns the sweep_amount to reduce the debt (senior tranche).
     * @param _sweep_amount Amount to be burnt by Sweep.
     * @dev Decreases the sweep borrowed.
     */
    function repay(uint256 _sweep_amount)
        external
        onlyBorrower
        validAmount(_sweep_amount)
    {
        _repay(_sweep_amount);
    }

    /**
     * @notice Invest USDX
     * Sends balances from the STABILIZER to the Asset.
     * @param _usdx_amount USDX Amount to be invested.
     * @param _sweep_amount Sweep Amount to be invested.
     */
    function invest(uint256 _usdx_amount, uint256 _sweep_amount)
        external
        onlyBorrower
        notFrozen
    {
        if (_usdx_amount > usdx.balanceOf(address(this)))
            _usdx_amount = usdx.balanceOf(address(this));

        if (_sweep_amount > sweep.balanceOf(address(this)))
            _sweep_amount = sweep.balanceOf(address(this));

        TransferHelper.safeApprove(address(usdx), address(asset), _usdx_amount);
        TransferHelper.safeApprove(
            address(sweep),
            address(asset),
            _sweep_amount
        );

        asset.deposit(_usdx_amount, _sweep_amount);

        emit Invested(_usdx_amount, _sweep_amount);
    }

    /**
     * @notice Divests From Asset.
     * Sends balance from the asset to the STABILIZER.
     * @param _amount Amount to be divested.
     */
    function divest(uint256 _amount)
        external
        onlyBorrower
        validAmount(_amount)
    {
        asset.withdraw(_amount);

        emit Divested(_amount);
    }

    /**
     * @notice Collect Rewards
     * Takes the rewards generated by the asset (On-Chain only).
     * @dev Rewards are sent to the borrower.
     */
    function collect() external onlyBorrower {
        asset.withdrawRewards(borrower);

        emit Collected(borrower);
    }

    /**
     * @notice Pay the spread to the treasury
     */
    function payFee() external onlyBorrower {
        _payFee();
    }

    /**
     * @notice Liquidates a stabilizer
     * a liquidator repays the debt in sweep and gets the same value 
     * of the assets that the stabilizer holds at a discount
     */
    function liquidate() external {
        if (!liquidatable) revert AssetNotLiquidatable();
        if (!isDefaulted()) revert NotDefaulted();

        uint256 debt = getDebt();
        TransferHelper.safeTransferFrom(
            address(sweep),
            msg.sender,
            address(this),
            debt
        );

        _repay(debt);

        uint256 liquidator_amount = (debt * PRECISION) / (1e6 - liquidator_discount);
        uint256 sweep_balance = sweep.balanceOf(address(this));
        uint256 usdx_balance = usdx.balanceOf(address(this));
        uint256 amount;

        if(sweep_balance > 0) {
            amount = _min(liquidator_amount, sweep_balance);
            liquidator_amount -= amount;
            TransferHelper.safeTransfer(address(sweep), msg.sender, amount);
        }

        liquidator_amount = sweep.convertToUSDX(liquidator_amount);

        if(usdx_balance > 0) {
            amount = _min(liquidator_amount, usdx_balance);
            liquidator_amount -= amount;
            if(amount > 0) TransferHelper.safeTransfer(address(usdx), msg.sender, amount);
        }

        uint256 current_value = asset.currentValue();
        amount = _min(liquidator_amount, current_value);
        liquidator_amount -= amount;
        if(amount > 0) asset.liquidate(msg.sender, amount);

        if(liquidator_amount > 0) {
            // writeoff / bad debt -> gets amount from treasury and pay the remanent
            // take (debt + fee) - sweep_balance
            revert('Not enough assets to pay the liquidator');
        }

        emit Liquidated(msg.sender);
    }

    /**
     * @notice Buy
     * Buys sweep_amount from the stabilizer's balance to the AMM (swaps USDX to SWEEP).
     * @param _usdx_amount Amount to be changed in the AMM.
     * @param _amountOutMin Minimum amount out.
     * @dev Increases the sweep balance and decrease usdx balance.
     */
    function buy(uint256 _usdx_amount, uint256 _amountOutMin)
        external
        onlyBorrower
        notFrozen
        validAmount(_usdx_amount)
        returns (uint256 sweep_amount)
    {
        sweep_amount = _buy(_usdx_amount, _amountOutMin);

        emit Bought(sweep_amount);
    }

    /**
     * @notice Sell Sweep
     * Sells sweep_amount from the stabilizer's balance to the AMM (swaps SWEEP to USDX).
     * @param _sweep_amount.
     * @param _amountOutMin Minimum amount out.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function sell(uint256 _sweep_amount, uint256 _amountOutMin)
        external
        onlyBorrower
        notFrozen
        validAmount(_sweep_amount)
        returns (uint256 usdx_amount)
    {
        if (_sweep_amount > sweep.balanceOf(address(this)))
            _sweep_amount = sweep.balanceOf(address(this));

        TransferHelper.safeApprove(address(sweep), address(amm), _sweep_amount);
        usdx_amount = amm.sellSweep(
            address(usdx),
            _sweep_amount,
            _amountOutMin
        );

        emit Sold(_sweep_amount);
    }

    /**
     * @notice Buy Sweep with Stabilizer
     * Buys sweep_amount from the stabilizer's balance to the Borrower (swaps USDX to SWEEP).
     * @param _usdx_amount.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function buySWEEP(uint256 _usdx_amount)
        external
        onlyBorrower
        notFrozen
        validAmount(_usdx_amount)
    {
        uint256 sweep_amount = (_usdx_amount * 10**sweep.decimals()) /
            sweep.target_price();
        if (sweep_amount > sweep.balanceOf(address(this)))
            revert NotEnoughBalance();

        TransferHelper.safeTransferFrom(
            address(usdx),
            msg.sender,
            address(this),
            _usdx_amount
        );
        TransferHelper.safeTransfer(address(sweep), msg.sender, sweep_amount);

        emit BoughtSWEEP(sweep_amount);
    }

    /**
     * @notice Sell Sweep with Stabilizer
     * Sells sweep_amount to the stabilizer (swaps SWEEP to USDX).
     * @param _sweep_amount.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function sellSWEEP(uint256 _sweep_amount)
        external
        onlyBorrower
        notFrozen
        validAmount(_sweep_amount)
    {
        uint256 usdx_amount = sweep.convertToUSDX(_sweep_amount);
        if (usdx_amount > usdx.balanceOf(address(this)))
            revert NotEnoughBalance();

        TransferHelper.safeTransferFrom(
            address(sweep),
            msg.sender,
            address(this),
            _sweep_amount
        );
        TransferHelper.safeTransfer(address(usdx), msg.sender, usdx_amount);

        emit SoldSWEEP(usdx_amount);
    }

    /**
     * @notice Withdraw SWEEP
     * Takes out sweep balance if the new equity ratio is higher than the minimum equity ratio.
     * @param _token.
     * @param _amount.
     * @dev Decreases the sweep balance.
     */
    function withdraw(address _token, uint256 _amount)
        external
        onlyBorrower
        notFrozen
        validAmount(_amount)
    {
        if (_token != address(sweep) && _token != address(usdx))
            revert InvalidToken();

        if (_amount > ERC20(_token).balanceOf(address(this)))
            revert NotEnoughBalance();

        if (sweep_borrowed != 0) {
            if (_token == address(sweep))
                _amount = sweep.convertToUSDX(_amount);
            int256 current_equity_ratio = calculateEquityRatio(0, _amount);
            if (current_equity_ratio < min_equity_ratio)
                revert EquityRatioExcessed();
        }

        TransferHelper.safeTransfer(_token, msg.sender, _amount);

        emit Withdrawn(_token, _amount);
    }

    function _buy(uint256 _usdx_amount, uint256 _amountOutMin)
        internal
        returns(uint256)
    {
        if (_usdx_amount > usdx.balanceOf(address(this)))
            _usdx_amount = usdx.balanceOf(address(this));

        TransferHelper.safeApprove(address(usdx), address(amm), _usdx_amount);
        uint256 sweep_amount = amm.buySweep(address(usdx), _usdx_amount, _amountOutMin);

        return sweep_amount;
    }

    function _repay(uint256 _sweep_amount)
        internal
    {
        if (_sweep_amount > sweep.balanceOf(address(this)))
            _sweep_amount = sweep.balanceOf(address(this));

        uint256 spread_amount = accruedFee();
        uint256 sweep_amount = _sweep_amount - spread_amount;
        if (sweep_borrowed < sweep_amount) {
            sweep_amount = sweep_borrowed;
            sweep_borrowed = 0;
        } else {
            sweep_borrowed -= sweep_amount;
        }
        TransferHelper.safeTransfer(
            address(sweep),
            sweep.treasury(),
            spread_amount
        );

        call_amount = call_amount > _sweep_amount ? (call_amount - _sweep_amount) : 0;

        TransferHelper.safeApprove(address(sweep), address(this), sweep_amount);
        spread_date = block.timestamp;
        sweep.minter_burn_from(sweep_amount);

        emit Repaid(sweep_amount);
    }

    function _payFee() internal {
        uint256 spread_amount = accruedFee();
        if (spread_amount > sweep.balanceOf(address(this)))
            revert SpreadNotEnough();

        if (spread_amount != 0) {
            TransferHelper.safeTransfer(
                address(sweep),
                sweep.treasury(),
                spread_amount
            );
        }
        spread_date = block.timestamp;

        emit PayFee(spread_amount);
    }

    function _min(uint256 a, uint256 b) internal pure returns(uint256) {
        return (a < b) ? a : b;
    }

    /**
     * @notice Calculate Equity Ratio
     * Calculated the equity ratio based on the internal storage.
     * @param _sweep_delta Variation of SWEEP to recalculate the new equity ratio.
     * @param _usdx_delta Variation of USDX to recalculate the new equity ratio.
     * @return the new equity ratio used to control the Mint and Withdraw functions.
     * @dev Current Equity Ratio percentage has a precision of 4 decimals.
     */
    function calculateEquityRatio(uint256 _sweep_delta, uint256 _usdx_delta)
        internal
        view
        returns (int256)
    {
        uint256 current_value = getCurrentValue();
        uint256 sweep_delta_in_usdx = sweep.convertToUSDX(_sweep_delta);
        uint256 senior_tranche_in_usdx = sweep.convertToUSDX(
            sweep_borrowed + _sweep_delta
        );
        uint256 total_value = current_value + sweep_delta_in_usdx - _usdx_delta;

        if (total_value == 0) return 0;

        // 1e6 is decimals of the percentage result
        int256 current_equity_ratio = ((int256(total_value) -
            int256(senior_tranche_in_usdx)) * 1e6) / int256(total_value);

        if (current_equity_ratio < -1e6) current_equity_ratio = -1e6;

        return current_equity_ratio;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface ISweep {
    struct Minter {
        uint256 max_amount;
        uint256 minted_amount;
        bool is_listed;
        bool is_enabled;
    }

    function DEFAULT_ADMIN_ADDRESS() external view returns (address);

    function balancer() external view returns (address);

    function treasury() external view returns (address);

    function collateral_agency() external view returns (address);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function isValidMinter(address) external view returns (bool);

    function amm_price() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function minter_burn_from(uint256 amount) external;

    function minter_mint(address m_address, uint256 m_amount) external;

    function minters(address m_address) external returns (Minter memory);

    function target_price() external view returns (uint256);

    function interest_rate() external view returns (int256);

    function period_time() external view returns (uint256);

    function step_value() external view returns (int256);

    function setInterestRate(int256 interest_rate) external;

    function setTargetPrice(uint256 current_target_price, uint256 next_target_price) external;    

    function startNewPeriod() external;

    function setUniswapOracle(address uniswap_oracle_address) external;

    function setTimelock(address new_timelock) external;

    function symbol() external view returns (string memory);

    function timelock_address() external view returns (address);

    function totalSupply() external view returns (uint256);

    function convertToUSDX(uint256 amount) external view returns (uint256);

    function convertToSWEEP(uint256 amount) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

import "../../../../Common/ERC20/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "STF"
        );
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ST"
        );
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SA"
        );
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }
}