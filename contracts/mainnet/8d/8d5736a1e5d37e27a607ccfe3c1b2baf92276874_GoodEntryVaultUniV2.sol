// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./GoodEntryVaultBase.sol";
import "../ammPositions/UniswapV2Position.sol";
import "../interfaces/IGoodEntryVault.sol";


/// @notice Vault with specific parameters for handling Uniswap v2 positions
contract GoodEntryVaultUniV2 is IGoodEntryVault, UniswapV2Position, GoodEntryVaultBase {
  using SafeERC20 for ERC20;
  
  
  /// @notice Initialize the vault, use after spawning a new proxy. Caller should be an instance of GoodEntryCore
  function initProxy(address _baseToken, address _quoteToken, address _positionManager, address weth, address _oracle) 
    public virtual override(IGoodEntryVault, GoodEntryVaultBase)
  {
    super.initProxy(_baseToken, _quoteToken, _positionManager,  weth,  _oracle);
    initAmm(_baseToken, _quoteToken);
  }
  
  
  /// @notice Withdraw all from AMM
  function withdrawAmm() internal override(UniswapV2Position, GoodEntryVaultBase) returns (uint baseAmount, uint quoteAmount) {
    (baseAmount, quoteAmount) = UniswapV2Position.withdrawAmm();
  }
  
  
  /// @notice Deposit in Amm
  function depositAmm(uint baseAmount, uint quoteAmount) internal override(UniswapV2Position, GoodEntryVaultBase) returns (uint liquidity) {
    liquidity = UniswapV2Position.depositAmm(baseAmount,  quoteAmount);
  }
  
  
  /// @notice Get AMM range amounts
  function getAmmAmounts() public view override returns (uint baseAmount, uint quoteAmount){
    (baseAmount,  quoteAmount) = _getReserves();
  }

  
  /// @notice Get Amm type 
  function ammType() public pure override(UniswapV2Position, IGoodEntryVault, GoodEntryVaultBase) returns (bytes32 _ammType){
    return UniswapV2Position.ammType();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


import "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../node_modules/@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "../../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../PositionManager/GoodEntryPositionManager.sol";
import "../interfaces/IGoodEntryVault.sol";
import "./VaultConfigurator.sol";
import "../GoodEntryCommons.sol";
import "./FeeStreamer.sol";


contract GoodEntryVaultBase is GoodEntryCommons, VaultConfigurator, ERC20("", ""), ReentrancyGuard, IGoodEntryVault, FeeStreamer {
  using SafeERC20 for ERC20;
  
  event Deposit(address indexed sender, address indexed token, uint amount, uint liquidity);
  event Withdraw(address indexed sender, address indexed token, uint amount, uint liquidity);
  event Borrowed(address indexed tickerAddress, uint tickerAmount);
  event Repaid(address indexed tickerAddress, uint tickerAmount);

  /// @notice Whitelist of position managers
  GoodEntryPositionManager public positionManager;
  
  /// @notice Withdrawals intents
  mapping(address => uint) public withdrawalIntents;
  uint public totalIntents;
  
  /// CONSTANTS 
  uint256 private constant Q96 = 0x1000000000000000000000000;
  uint256 private constant UINT256MAX = type(uint256).max;
  
  
  modifier onlyOPM() {
    require(address(positionManager) == msg.sender, "GEV: Unallowed PM");
    _;
  }
  
  /// @notice Initialize the vault, use after spawning a new proxy. Caller should be an instance of GoodEntryCore
  function initProxy(address _baseToken, address _quoteToken, address _positionManager, address weth, address _oracle) public virtual {
    require(address(goodEntryCore) == address(0), "GEV: Already Init");
    require(_baseToken != address(0) && _quoteToken != address(0) && _oracle != address(0), "GEV: Zero Address");
    _transferOwnership(msg.sender);
    goodEntryCore = IGoodEntryCore(msg.sender);
    baseToken = ERC20(_baseToken);
    quoteToken = ERC20(_quoteToken);
    oracle = IGoodEntryOracle(_oracle);
    WETH = IWETH(weth);
    positionManager = GoodEntryPositionManager(_positionManager);
    initializeConfig();
  }
  
  
  //////// DEOSIT/WITHDRAW FUNCTIONS

  /// @notice Withdraw assets from the ticker
  /// @param liquidity Amount of GEV tokens to redeem; if 0, redeem all
  /// @param token Address of the token redeemed for
  /// @return amount Total token returned
  function withdraw(uint liquidity, address token) public returns (uint amount) {
    amount = _withdraw(msg.sender, liquidity, token);
  }
  

  /// @notice withdraw for another user who placed a withdrawal intent
  /// @dev prevents griefing by diluting the vault yields with funds marked for withdrawals but never withdrawn
  function withdrawOnBehalf(address onBehalfOf, uint liquidity, address token) public onlyOwner returns (uint amount) {
    require(withdrawalIntents[onBehalfOf] >= liquidity, "GEV: Intent Too Low");
    amount = _withdraw(onBehalfOf, liquidity, token);
  }
  
  
  function _withdraw(address user, uint liquidity, address token) internal nonReentrant returns (uint amount){
    require(token == address(baseToken) || token == address(quoteToken), "GEV: Invalid Token");
    require(liquidity <= balanceOf(user), "GEV: Insufficient Balance");
    if(liquidity == 0) liquidity = balanceOf(user);
    if(liquidity == 0) return 0;
    
    (,,uint vaultValueX8) = getReserves();
    uint valueX8 = vaultValueX8 * liquidity / totalSupply();
    amount = valueX8 * 10**ERC20(token).decimals() / oracle.getAssetPrice(token);
    uint fee = amount * getAdjustedBaseFee(token == address(quoteToken)) / FEE_MULTIPLIER;
    
    _burn(user, liquidity);
    withdrawAmm();
    ERC20(token).safeTransfer(goodEntryCore.treasury(), fee);
    uint bal = amount - fee;

    if (token == address(WETH)){
      WETH.withdraw(bal);
      (bool success, ) = payable(user).call{value: bal}("");
      require(success, "GEV: Error sending ETH");
    }
    else {
      ERC20(token).safeTransfer(user, bal);
    }
    
    // reset withdrawal intent
    totalIntents -= withdrawalIntents[user];
    withdrawalIntents[user] = 0;
    // Check utilization rate after transfer processed
    (uint utilizationRate, uint maxRate) = positionManager.getUtilizationRateStatus();
    require(utilizationRate <= maxRate, "GEV: Utilization Rate too high");
    
    deployAssets();
    emit Withdraw(user, token, amount, liquidity);
  }
  

  


  /// @notice deposit tokens in the pool, convert to WETH if necessary
  /// @param token Token address
  /// @param amount Amount of token deposited
  function deposit(address token, uint amount) public payable nonReentrant returns (uint liquidity) {
    require(amount > 0 || msg.value > 0, "GEV: Deposit Zero");
    require(!goodEntryCore.isPaused(), "GEV: Pool Disabled");
    require(token == address(baseToken) || token == address(quoteToken), "GEV: Invalid Token");
    
    withdrawAmm();
    (,,uint vaultValueX8) = getReserves();
    uint adjBaseFee = getAdjustedBaseFee(token == address(baseToken));
    // Wrap if necessary and deposit here
    if (msg.value > 0){
      require(token == address(WETH), "GEV: Invalid Weth");
      // wraps ETH by sending to the wrapper that sends back WETH
      WETH.deposit{value: msg.value}();
      amount = msg.value;
    }
    else { 
      ERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }
    
    // Send deposit fee to treasury
    uint fee = amount * adjBaseFee / FEE_MULTIPLIER;
    ERC20(token).safeTransfer(goodEntryCore.treasury(), fee);
    uint valueX8 = oracle.getAssetPrice(token) * (amount - fee) / 10**ERC20(token).decimals();
    
    require(tvlCapX8 == 0 || tvlCapX8 > valueX8 + vaultValueX8, "GEV: Max Cap Reached");

    uint tSupply = totalSupply();
    // initial liquidity at 1e18 token ~ $1
    if (tSupply == 0 || vaultValueX8 == 0)
      liquidity = valueX8 * 1e10;
    else
      liquidity = tSupply * valueX8 / vaultValueX8;
    
    deployAssets();
    require(liquidity > 0, "GEV: No Liquidity Added");
    _mint(msg.sender, liquidity);

    // Prevent inflation attack
    if (liquidity == totalSupply()) _mint(0x000000000000000000000000000000000000dEaD, liquidity / 100);
    emit Deposit(msg.sender, token, amount, liquidity);
  }

  
  /// @notice Update a user withdrawal intent
  function setWithdrawalIntent(uint intentAmount) public {
    require(intentAmount <= balanceOf(msg.sender), "GEV: Intent too high");
    uint previousIntent = withdrawalIntents[msg.sender];
    if (previousIntent > 0) totalIntents -= previousIntent;
    withdrawalIntents[msg.sender] = intentAmount;
    totalIntents += intentAmount;
  }
  
  /// @notice Reset withdrawal intent before transfers
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    uint intentAmount = withdrawalIntents[from];
    withdrawalIntents[from] = 0;
    totalIntents -= intentAmount;
  }

  
  //////// BORROWING FUNCTIONS
  
  
  /// @notice Allow an OPM to borrow assets and keep accounting of the debt
  function borrow(address token, uint amount) public onlyOPM nonReentrant {
    require(!goodEntryCore.isPaused(), "GEV: Pool Disabled");
    withdrawAmm();
    require(ERC20(token).balanceOf(address(this)) >= amount, "GEV: Not Enough Supply");
    
    ERC20(token).safeTransfer(msg.sender, amount);
    deployAssets();
    emit Borrowed(address(token), amount);
  }
  
  
  /// @notice Allows OPM to return funds when a position is closed
  function repay(address token, uint amount, uint fees) public onlyOPM nonReentrant {
    require(amount > 0, "GEV: Invalid Debt");
    withdrawAmm();
    
    if(token == address(quoteToken)) quoteToken.safeTransferFrom(msg.sender, address(this), amount + fees);
    else {
      ERC20(token).safeTransferFrom(msg.sender, address(this), amount);
      quoteToken.safeTransferFrom(msg.sender, address(this), fees);
    }
    oracle.getAssetPrice(address(quoteToken));
    if (fees > 0) {
      uint treasuryFees = fees * goodEntryCore.treasuryShareX2() / 100;
      quoteToken.safeTransfer(goodEntryCore.treasury(), treasuryFees);
      uint vaultFees = fees - treasuryFees;
      reserveFees(0, vaultFees, vaultFees * oracle.getAssetPrice(address(quoteToken)) / 10**quoteToken.decimals());
    }
    deployAssets();
    emit Repaid(token, amount);
  }


  //////// INTERNAL FUNCTIONS, OVERRIDEN
  
  /// @notice Get AMM range amounts
  function getAmmAmounts() public view virtual returns (uint baseAmount, uint quoteAmount){}
  /// @notice Withdraw from Amm
  function withdrawAmm() internal virtual returns (uint baseAmount, uint quoteAmount){}
  /// @notice Deposit in Amm
  function depositAmm(uint baseAmount, uint quoteAmount) internal virtual returns (uint liq) {}
  
  
  /// @notice Deploy assets in tickSpread ticks above and below current price
  function deployAssets() internal { 
    if (goodEntryCore.isPaused()) return;

    uint baseAvail = baseToken.balanceOf(address(this));
    uint quoteAvail = quoteToken.balanceOf(address(this));
    (uint basePending, uint quotePending) = getPendingFees();
    // deposit a part of the assets in the full range. No slippage control in TR since we already checked here for sandwich
    if (baseAvail > basePending && quoteAvail > quotePending) 
      depositAmm((baseAvail - basePending) * ammPositionShareX2 / 100, (quoteAvail - quotePending) * ammPositionShareX2 / 100);
  }
  
  
  /// @notice Get vault underlying assets
  function getReserves() public view returns (uint baseAmount, uint quoteAmount, uint valueX8){
    (baseAmount, quoteAmount) = _getVaultReserves();
    valueX8 = baseAmount  * oracle.getAssetPrice(address(baseToken))  / 10**baseToken.decimals() 
            + quoteAmount * oracle.getAssetPrice(address(quoteToken)) / 10**quoteToken.decimals();
  }
  
  
  /// @notice Get vault reserves adjusted for withdraw intents
  function getAdjustedReserves() public view returns (uint baseAmount, uint quoteAmount){
    (baseAmount, quoteAmount) = _getVaultReserves();
    uint totalSupply = totalSupply();
    if (totalIntents > 0 && totalSupply > 0) {
      uint adjustedShare = totalSupply - totalIntents;
      baseAmount = baseAmount * adjustedShare / totalSupply;
      quoteAmount = quoteAmount * adjustedShare / totalSupply;
    }
  }
  
  
  function _getVaultReserves() private view returns (uint baseAmount, uint quoteAmount){
    (baseAmount, quoteAmount) = getAmmAmounts();
    
    // add borrowed amounts
    (uint baseDue, uint quoteDue) = positionManager.getAssetsDue();
    baseAmount += baseDue + baseToken.balanceOf(address(this));
    quoteAmount += quoteDue + quoteToken.balanceOf(address(this));
    
    // deduce pending fees - should never be larger than balance but check to avoid breaking the pool if that happens
    (uint basePending, uint quotePending) = getPendingFees();
    baseAmount  = basePending < baseAmount ? baseAmount - basePending : 0;
    quoteAmount  = quotePending < quoteAmount ? quoteAmount - quotePending : 0;
  }


  /// @notice Get deposit fee
  /// @param increaseBase Whether (base is added || quote removed) or not
  /// @dev Simple linear model: from baseFeeX4 / 2 to baseFeeX4 * 3 / 2
  function getAdjustedBaseFee(bool increaseBase) public view returns (uint adjustedBaseFeeX4) {
    uint baseFeeX4_ = uint(baseFeeX4);
    (uint baseRes, uint quoteRes, ) = getReserves();
    uint valueBase  = baseRes  * oracle.getAssetPrice(address(baseToken))  / 10**baseToken.decimals();
    uint valueQuote = quoteRes * oracle.getAssetPrice(address(quoteToken)) / 10**quoteToken.decimals();

    if (increaseBase) adjustedBaseFeeX4 = baseFeeX4_ * valueBase  / (valueQuote + 1);
    else              adjustedBaseFeeX4 = baseFeeX4_ * valueQuote / (valueBase  + 1);

    // Adjust from -50% to +50%
    if (adjustedBaseFeeX4 < baseFeeX4_ / 2) adjustedBaseFeeX4 = baseFeeX4_ / 2;
    if (adjustedBaseFeeX4 > baseFeeX4_ * 3 / 2) adjustedBaseFeeX4 = baseFeeX4_ * 3 / 2;
  }


  /// @notice fallback: deposit unless it.s WETH being unwrapped
  receive() external payable {
    if(msg.sender != address(WETH)) deposit(address(WETH), msg.value);
  }
  
  
  /// @notice Helper that checks current allowance and approves if necessary
  /// @param token Target token
  /// @param spender Spender
  /// @param amount Amount below which we need to approve the token spending
  function checkSetApprove(ERC20 token, address spender, uint amount) internal {
    uint currentAllowance = token.allowance(address(this), spender);
    if (currentAllowance < amount) token.safeIncreaseAllowance(spender, UINT256MAX - currentAllowance);
  }


  /// @notice Get the base asset price in quote tokens
  function getBasePrice() public view returns (uint priceX8) {
    priceX8 = oracle.getAssetPrice(address(baseToken)) * 1e8 / oracle.getAssetPrice(address(quoteToken));
  }
  
  
  /// @notice Return underlying tokens
  function tokens() public view returns (address, address){
    return (address(baseToken),  address(quoteToken));
  }
  
  /// @notice Return AMM type, which is none for base vault
  function ammType() public pure virtual returns (bytes32 _ammType){
    _ammType = "";
  }
  

  /// @notice Get the name of this contract token
  function name() public view virtual override returns (string memory) { 
    return string(abi.encodePacked("GoodEntry ", baseToken.symbol(), "-", quoteToken.symbol()));
  }
  /// @notice Get the symbol of this contract token
  function symbol() public view virtual override returns (string memory _symbol) {
    _symbol = "Good-LP";
  }
  
  function getPastFees(uint period) public view returns (uint baseAmount, uint quoteAmount){
    baseAmount = periodToFees0[period];
    quoteAmount = periodToFees1[period];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AmmPositionBase.sol";
import "../../node_modules/@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../../node_modules/@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../../node_modules/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


/**
 * @title UniswapV2Position
 * @author GoodEntry
 * @dev Allows depositing liquidity in a regular Uniswap v2 style AMM
 */
contract UniswapV2Position is AmmPositionBase {
  
  address private lpToken;
  
  // Using Sushiswap as default Arbitrum v2 router; Camelot V2: 0xc873fEcbd354f5A56E00E710B90EF4201db2448d
  IUniswapV2Router02 private constant ROUTER_V2 = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
  
  /// @notice ammType name
  function ammType() public pure virtual override returns (bytes32 _ammType) {
    _ammType = "UniswapV2";
  }
  
  
  /// @notice Called on setup
  function initAmm(address _baseToken, address _quoteToken) internal {
    lpToken = IUniswapV2Factory(ROUTER_V2.factory()).getPair(_baseToken, _quoteToken);
    require(lpToken != address(0), "TR: No Such Pool");
  }
  
  
  /// @notice Deposit assets
  function depositAmm(uint baseAmount, uint quoteAmount) internal virtual override returns (uint liquidity) {
    if (baseAmount > 0 && quoteAmount > 0) {
      checkSetApprove(address(baseToken), address(ROUTER_V2), baseAmount);
      checkSetApprove(address(quoteToken), address(ROUTER_V2), quoteAmount);
      (,, liquidity) = ROUTER_V2.addLiquidity(address(baseToken), address(quoteToken), baseAmount, quoteAmount, 0, 0, address(this), block.timestamp);
    }
  }
  
  
  /// @notice Withdraw
  function withdrawAmm() internal virtual override returns (uint256 removed0, uint256 removed1) {
    require(poolPriceMatchesOracle(), "TR: Oracle Price Mismatch");
    uint bal = ERC20(lpToken).balanceOf(address(this));
    checkSetApprove(lpToken, address(ROUTER_V2), bal);
    if (bal > 0) (removed0, removed1) = ROUTER_V2.removeLiquidity(address(baseToken), address(quoteToken), bal, 0, 0, address(this), block.timestamp);
  }
  
  
  /// @notice This range underlying token amounts
  function _getReserves() internal override view returns (uint baseAmount, uint quoteAmount) {
    uint supply = ERC20(lpToken).totalSupply();
    if (supply == 0) return (0, 0);
    uint share = ERC20(lpToken).balanceOf(address(this));
    
    (uint amount0, uint amount1, ) = IUniswapV2Pair(lpToken).getReserves();
    amount0 = amount0 * share / supply;
    amount1 = amount1 * share / supply;
    
    (baseAmount,  quoteAmount) = baseToken < quoteToken ? (amount0, amount1) : (amount1, amount0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


interface IGoodEntryVault  {
  function tokens() external returns (address, address);
  function withdraw(uint liquidity, address token) external returns (uint amount);
  function deposit(address token, uint amount) external payable returns (uint liquidity);
  function borrow(address asset, uint amount) external;
  function repay(address token, uint amount, uint fees) external;
  function getReserves() external view returns (uint baseAmount, uint quoteAmount, uint valueX8);
  function getAdjustedReserves() external view returns (uint baseAmount, uint quoteAmount);
  function getAdjustedBaseFee(bool increaseToken0) external view returns (uint adjustedBaseFeeX4);
  function getBasePrice() external view returns (uint priceX8);
  function initProxy(address _baseToken, address _quoteToken, address _positionManager, address weth, address _oracle) external;
  function ammType() external pure returns (bytes32 _ammType);
  function setWithdrawalIntent(uint intentAmount) external;
  function getPastFees(uint period) external view returns (uint baseAmount, uint quoteAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../interfaces/IGeNftDescriptor.sol";
import "../interfaces/IGoodEntryPositionManager.sol";
import "../interfaces/IVaultConfigurator.sol";
import "../interfaces/IGoodEntryVault.sol";
import "../interfaces/IGoodEntryCore.sol";
import "../interfaces/IReferrals.sol";
import "./StrikeManager.sol";
import "../GoodEntryCommons.sol";


contract GoodEntryPositionManager is GoodEntryCommons, ERC721Enumerable, IGoodEntryPositionManager {
  using SafeERC20 for ERC20;

  event OpenedPosition(address indexed user, bool indexed isCall, uint indexed strike, uint amount, uint tokenId);
  event ClosedPosition(address indexed user, address closer, uint tokenId, int pnl);

  mapping(uint => Position) private _positions;
  uint private _nextPositionId;
  
  uint public openInterestCalls;
  uint public openInterestPuts;
  mapping(uint => uint) public strikeToOpenInterestCalls;
  mapping(uint => uint) public strikeToOpenInterestPuts;
  /// @notice Tracks all strikes with non zero OI
  mapping(uint => uint) private openStrikeIds;
  uint[] public openStrikes;
  
  /// @notice Vault from which to borrow
  address public vault;
  /// @notice Referrals contract
  IReferrals private referrals;

  // maximum OI in percent of total vault assets
  uint8 private constant MAX_UTILIZATION_RATE = 60;
  // time to expiry for streaming options
  uint private constant STREAMING_OPTION_TTE = 14400;
  // min position size: avoid dust sized positions that create liquidation issues
  uint private constant MIN_POSITION_VALUE_X8 = 40e8;
  // @notice flat closing gas fee if position closed by 3rd party // currently based on USDC 6 decimals
  uint private constant FIXED_EXERCISE_FEE = 4e6;
  
  uint private constant YEARLY_SECONDS = 31_536_000;
  uint private constant UINT256MAX = type(uint256).max;
  // Max open strikes as looping on strikes to get amounts due is costly, excess would break. when reaching max, allow forced liquidations
  uint private constant MAX_OPEN_STRIKES = 200; 
  // Min amount of collateral in a streaming position
  uint private constant MIN_COLLATERAL_AMOUNT = 1e6;
  // Min/max tte for regular options
  uint private constant MIN_FIXED_OPTIONS_TTE = 86400;
  uint private constant MAX_FIXED_OPTIONS_TTE = 86400 * 10;
  // Address of the NFT descriptor library beacon
  address private constant GENFT_PROXY = 0xBFD31f052d1dD207Bc4FfD9DD60EF2E00b9b531E;
  // Max strike distance to avoid DOS attacks by opening very deep OTM options with low cost and filling up allowed open strikes pool
  uint8 private constant MAX_STRIKE_DISTANCE_X2 = 25;
  // Min elapsed duration time: prevents exploit where extremly short options are used to make a systematicly profitable strat
  // A 2h 
  uint private constant MIN_ELAPSED_DURATION = 5400;

  constructor() ERC721("GoodEntry V2 Positions", "GEP") {}

  function initProxy(address _oracle, address _baseToken, address _quoteToken, address _vault, address _referrals) public {
    require(vault == address(0x0), "PM: Already Init");
    vault = _vault;
    baseToken = ERC20(_baseToken);
    quoteToken  = ERC20(_quoteToken);
    oracle = IGoodEntryOracle(_oracle);
    openStrikes.push(0); // dummy value, invalid openStrikeIds
    referrals = IReferrals(_referrals);
  }
  
  
  /// @notice Getter for pm parameters
  function getParameters() public view returns (uint, uint, uint, uint, uint, uint, uint8, uint8, uint) {
    return (
      MIN_POSITION_VALUE_X8, 
      MIN_COLLATERAL_AMOUNT, 
      FIXED_EXERCISE_FEE, 
      STREAMING_OPTION_TTE, 
      MIN_FIXED_OPTIONS_TTE, 
      MAX_FIXED_OPTIONS_TTE, 
      MAX_UTILIZATION_RATE, 
      MAX_STRIKE_DISTANCE_X2,
      MIN_ELAPSED_DURATION
    );
  }


  /// @notice Get open strikes length
  function getOpenStrikesLength() public view returns (uint) { return openStrikes.length; }

  
  /// @notice Get position by Id
  function getPosition(uint tokenId) public view returns (Position memory) {
    return _positions[tokenId];
  }
  
  /// @notice Get a nice NFT representation of a position
  function tokenURI(uint256 tokenId) public view override(ERC721, IERC721Metadata) returns (string memory) {
    Position memory position = _positions[tokenId];
    (, uint pnl) = getValueAtStrike(position.isCall, IGoodEntryVault(vault).getBasePrice(), position.strike, position.notionalAmount);
    (uint feesDue, uint feesMin) = getFeesAccumulatedAndMin(tokenId);
    int actualPnl = int(pnl) - int(feesDue);
    return IGeNftDescriptor(GENFT_PROXY).constructTokenURI(IGeNftDescriptor.ConstructTokenURIParams(
      tokenId, address(quoteToken), address(baseToken), quoteToken.symbol(), baseToken.symbol(), position.isCall, actualPnl
    ));

  }
  
  
  /// @notice Opens a fixed duration option
  function openFixedPosition(bool isCall, uint strike, uint notionalAmount, uint timeToExpiry) external returns (uint tokenId){
    require(timeToExpiry >= MIN_FIXED_OPTIONS_TTE, "GEP: Min Duration");
    require(timeToExpiry <= MAX_FIXED_OPTIONS_TTE, "GEP: Max Duration");
    require(StrikeManager.isValidStrike(strike), "GEP: Invalid Strike");
    uint basePrice = IGoodEntryVault(vault).getBasePrice();
    require((isCall && basePrice <= strike) || (!isCall && basePrice >= strike), "GEP: Not OTM");
    uint strikeDistance = isCall ? strike - basePrice : basePrice - strike;
    require(100 * strikeDistance / basePrice <= MAX_STRIKE_DISTANCE_X2, "GEP: Strike too far OTM");
    return openPosition(isCall, strike, notionalAmount, 0, timeToExpiry);
  }
  
  /// @notice Opens a streaming option which is a 6h expiry option paying a pay-as-you-go funding rate
  function openStreamingPosition(bool isCall, uint notionalAmount, uint collateralAmount) external returns (uint tokenId){
    require(collateralAmount >= MIN_COLLATERAL_AMOUNT, "GEP: Min Collateral Error");
    // Use 0 as strike for streaming option, it will take the closest one
    return openPosition(isCall, 0, notionalAmount, collateralAmount, 0);
  }
  
  /// @notice Open an option streaming position by borrowing an asset from the vault
  /// @param isCall Call or put
  /// @param collateralAmount if isStreamingOption, should give a collateral amount to deposit
  /// @param timeToExpiry if fixed duration (not isStreamingOption), end date will define option price and Collateral transferred from buyer
  function openPosition(bool isCall, uint strike, uint notionalAmount, uint collateralAmount, uint timeToExpiry) internal returns (uint tokenId) {
    uint basePrice = IGoodEntryVault(vault).getBasePrice();
    bool isStreamingOption = strike == 0;
    if(isStreamingOption) strike = isCall ? 
      StrikeManager.getStrikeStrictlyAbove(StrikeManager.getStrikeAbove(basePrice)) 
      : StrikeManager.getStrikeStrictlyBelow(StrikeManager.getStrikeBelow(basePrice));

    uint positionValueX8 = notionalAmount * oracle.getAssetPrice(address(isCall ? baseToken : quoteToken)) 
                                          / 10**ERC20(isCall ? baseToken : quoteToken).decimals();
    require(positionValueX8 >= MIN_POSITION_VALUE_X8, "GEP: Min Size Error");
    uint optionCost = getOptionCost(isCall, strike, notionalAmount, isStreamingOption ? STREAMING_OPTION_TTE : timeToExpiry);
    // Scale optionCost up for high leverage streaming options: above 200x, add 20% * (leverage - 200) / 500
    if (collateralAmount > 0 ){
      uint leverage = positionValueX8 / (collateralAmount * 100);
      if (leverage > 250) optionCost = optionCost * (100 + 20 * (leverage - 250) / 25) / 100;
    }
    // Funding rate in quoteToken per second X10
    uint fundingRateX10 = 1e10 * optionCost / STREAMING_OPTION_TTE;
    
    // Actual collateral amount
    collateralAmount = FIXED_EXERCISE_FEE + (isStreamingOption ? collateralAmount : optionCost);
    
    tokenId = _nextPositionId++;
    _positions[tokenId] = Position(
      isCall,
      isStreamingOption ? IGoodEntryPositionManager.OptionType.StreamingOption : IGoodEntryPositionManager.OptionType.FixedOption, 
      strike, 
      notionalAmount, 
      collateralAmount,
      block.timestamp, 
      isStreamingOption ? fundingRateX10 : block.timestamp + timeToExpiry
    );
    _mint(msg.sender, tokenId);

    // Borrow assets, those are sent here
    IGoodEntryVault(vault).borrow(address(isCall ? baseToken : quoteToken), notionalAmount);
    ERC20(quoteToken).safeTransferFrom(msg.sender, address(this), collateralAmount);

    // Start tracking if new strike
    if (openStrikeIds[strike] == 0) {
      openStrikes.push(strike);
      openStrikeIds[strike] = openStrikes.length - 1;
    }
    // Update OI
    if (isCall) {
      strikeToOpenInterestCalls[strike] += notionalAmount;
      openInterestCalls += notionalAmount;
    }
    else {
      strikeToOpenInterestPuts[strike] += notionalAmount;
      openInterestPuts += notionalAmount;
    }
    
    emit OpenedPosition(msg.sender, isCall, strike, notionalAmount, tokenId);
  }
  
  
  /// @notice Increase the collateral to maintain a position open for longer
  function increaseCollateral(uint tokenId, uint newCollateralAmount) public {
  require(_positions[tokenId].optionType == IGoodEntryPositionManager.OptionType.StreamingOption, "GEP: Not Streaming Option");
    ERC20(quoteToken).safeTransferFrom(msg.sender, address(this), newCollateralAmount);
    _positions[tokenId].collateralAmount += newCollateralAmount;
  }
  
  
  /// @notice Close a position and get some collateral back
  function closePosition(uint tokenId) external {
    address owner = ownerOf(tokenId);
    Position memory position = _positions[tokenId];
    address positionToken = address(position.isCall ? baseToken : quoteToken);
    uint remainingCollateral = position.collateralAmount;
    // Collateral spent over time as funding fees increase
    (uint feesDue, uint feesMin) = getFeesAccumulatedAndMin(tokenId);
    require(
      msg.sender == owner
        || (position.optionType == IGoodEntryPositionManager.OptionType.StreamingOption && feesDue >= position.collateralAmount - FIXED_EXERCISE_FEE)
        || (position.optionType == IGoodEntryPositionManager.OptionType.FixedOption && block.timestamp >= position.data )
        ||  _isEmergencyStrike(position.strike),
        "GEP: Invalid Close"
    );
    if (feesMin > feesDue) feesDue = feesMin;
    
    _burn(tokenId);
    // Invariant check for notional token: vaultDue + pnl = notionalAmount, which was received from the vault when the position was opened
    (uint vaultDue, uint posPnl) = getValueAtStrike(position.isCall, IGoodEntryVault(vault).getBasePrice(), position.strike, position.notionalAmount);
    
    if(position.isCall) checkSetApprove(address(baseToken), vault, vaultDue);
    checkSetApprove(address(quoteToken), vault, vaultDue + feesDue);
    // Referee discount is deduced from option price at open. Referrer  rebate is received from actual fees on close
    (address referrer, uint16 rebateReferrer,) = address(referrals) != address(0x0) ? referrals.getReferralParameters(owner) : (address(0x0), 0, 0);
    uint feesRebate;
    if(referrer != address(0x0) && rebateReferrer > 0) {
      feesRebate = feesDue * rebateReferrer / 10000;
      quoteToken.safeTransfer(referrer, feesRebate);
    }
    IGoodEntryVault(vault).repay(positionToken, vaultDue, feesDue - feesRebate);
    remainingCollateral -= feesDue;
    
    if (posPnl > 0) ERC20(positionToken).safeTransfer(owner, posPnl);
    
    // if exercise time reached, anyone can close the position and claim half of the fixed closing fee, other half goes to treasury
    if (owner != msg.sender) {
      quoteToken.safeTransfer(IGoodEntryCore(IVaultConfigurator(vault).goodEntryCore()).treasury(), FIXED_EXERCISE_FEE / 2);
      quoteToken.safeTransfer(msg.sender, FIXED_EXERCISE_FEE / 2);
      remainingCollateral -= FIXED_EXERCISE_FEE;
    }
    // Invariant: on closing position, no more than the colalteral deposited has been transfered out
    if (remainingCollateral > 0) quoteToken.safeTransfer(owner, remainingCollateral);
    // Invariant check collateral token: the amounts transfered as fees / remainder are deduced step by step from the collateral received
    // Any excess would cause a revert
    
    // update OI state
    if (position.isCall) {
      strikeToOpenInterestCalls[position.strike] -= position.notionalAmount;
      openInterestCalls -= position.notionalAmount;
    }
    else {
      strikeToOpenInterestPuts[position.strike] -= position.notionalAmount;
      openInterestPuts -= position.notionalAmount;
    }
    checkStrikeOi(position.strike);
    // pnl: position Pnl - fees, for event and tracking purposes (and pretty NFTs!)
    {
      int pnl = int(posPnl * oracle.getAssetPrice(positionToken) / 10**ERC20(positionToken).decimals())
              - int((position.collateralAmount - remainingCollateral) * oracle.getAssetPrice(address(quoteToken)) / 10**quoteToken.decimals());
      emit ClosedPosition(owner, msg.sender, tokenId, pnl);
    }
  }
  
  
  // @notice Remove a strike from OI list if OI of both puts and calls is 0
  function checkStrikeOi(uint strike) internal {
    if(strikeToOpenInterestCalls[strike] + strikeToOpenInterestPuts[strike] == 0){
      uint strikeId = openStrikeIds[strike];
      if(strikeId < openStrikes.length - 1){
        // if not last element, replace by last
        uint lastStrike = openStrikes[openStrikes.length - 1];
        openStrikes[strikeId] = lastStrike;
        openStrikeIds[lastStrike] = openStrikeIds[strike];
      }
      openStrikeIds[strike] = 0;
      openStrikes.pop();
    }
  }
  
  
  /// @notice Calculate fees accumulated by a position // for compatibility, unused
  function getFeesAccumulated(uint tokenId) public view returns (uint feesAccumulated){
    (feesAccumulated,) = getFeesAccumulatedAndMin(tokenId);
  }
  
  
  /// @notice Calculate fees accumulated by a position and the minimal fees perceived
  function getFeesAccumulatedAndMin(uint tokenId) public view returns (uint feesAccumulated,  uint feesMin) {
    Position memory position = _positions[tokenId];
    uint collateralAmount = position.collateralAmount - FIXED_EXERCISE_FEE;
    if (position.optionType == IGoodEntryPositionManager.OptionType.StreamingOption){
      uint elapsed = block.timestamp - position.startDate;
      feesAccumulated = position.data * elapsed / 1e10;
      if (feesAccumulated > collateralAmount) feesAccumulated = collateralAmount;
      feesMin = position.data * MIN_ELAPSED_DURATION / 1e10;
      if (feesMin > collateralAmount) feesMin = collateralAmount;
    }
    else 
      feesAccumulated = collateralAmount;
  }
  


  /// @notice Calculate option debt due and user pnl
  function getValueAtStrike(bool isCall, uint price, uint strike, uint amount) public pure returns (uint vaultDue, uint pnl) {
    if(isCall  && price > strike) pnl = amount * (price - strike) / price;
    if(!isCall && price < strike) pnl = amount * (strike - price) / strike;
    vaultDue = amount - pnl;
    // By design, vaultDue + pnl = amount
  }
  
  
  /// @notice Get assets due to the vault: loop on open strikes to get value based on price and strikes
  function getAssetsDue() public view returns (uint baseAmount, uint quoteAmount) {
    if (openStrikes.length > 1){
      uint price = IGoodEntryVault(vault).getBasePrice();
      for(uint strike = 1; strike < openStrikes.length; strike++){
        (uint baseDue,) = getValueAtStrike(true, price, openStrikes[strike], strikeToOpenInterestCalls[openStrikes[strike]]);
        baseAmount += baseDue;
        (uint quoteDue,) = getValueAtStrike(false, price, openStrikes[strike], strikeToOpenInterestPuts[openStrikes[strike]]);
        quoteAmount += quoteDue;
      }
    }
  }
  
  
  /// @notice Get the option actual cost based on price, tokens, discounts, .
  function getOptionCost(bool isCall, uint strike, uint notionalAmount, uint timeToExpirySec) public view returns (uint optionCost){
    // Use internal function _getUtilizationRate to save on getReserves() which is very very expensive
    (uint baseBalance, uint quoteBalance) = IGoodEntryVault(vault).getAdjustedReserves();

    uint utilizationRate = _getUtilizationRate(baseBalance, quoteBalance, isCall, notionalAmount);
    require(utilizationRate <= MAX_UTILIZATION_RATE, "GEP: Max OI Reached");

    utilizationRate = _getUtilizationRate(baseBalance, quoteBalance, isCall, notionalAmount / 2);
    // unitary cost in quote tokens X8 (need to adjust for quote token decimals below)
    optionCost = oracle.getOptionPrice(isCall, address(baseToken), address(quoteToken), strike, timeToExpirySec, utilizationRate);

    // Referee discount is deduced from option price at open. Referrer  rebate is received from actual fees on close
    (,, uint16 discountReferee) = address(referrals) != address(0x0) ? referrals.getReferralParameters(msg.sender) : (address(0x0), 0, 0);
    if (discountReferee > 0) optionCost = optionCost * (10000 - discountReferee) / 10000;
    // total cost: multiply price by size in base token
    // for a put: eg: short ETH at strike 2000 with 4000 USDC -> size = 2
    if (isCall) optionCost = optionCost * notionalAmount * 10**quoteToken.decimals() / 10**baseToken.decimals() / 1e8;
    else optionCost = optionCost * notionalAmount / strike;
  }
  
    
  /// @notice Get the option price for a given strike, in quote tokens
  /// @dev Utilization rate with size/2 so that opening 1 large or 2 smaller positions have approx the same expected funding
  function getOptionPrice(bool isCall, uint strike, uint size, uint timeToExpirySec) public view returns (uint optionPrice) {
    optionPrice = oracle.getOptionPrice(isCall, address(baseToken), address(quoteToken), strike, timeToExpirySec, getUtilizationRate(isCall, size / 2));
  }
  
  
  /// @notice Get utilization rate at strike in percent
  /// @dev it could make sense to aggregate over a rolling window, eg oi(strikeAbove) + oi(strikeBelow) < 2 * maxOI
  function getUtilizationRate(bool isCall, uint addedAmount) public view returns (uint utilizationRate) {
    (uint baseBalance, uint quoteBalance) = IGoodEntryVault(vault).getAdjustedReserves();
    utilizationRate = _getUtilizationRate(baseBalance, quoteBalance, isCall, addedAmount);
  }
  
  
  /// @notice Calculate utilization rate based on token balances
  function _getUtilizationRate(uint baseBalance, uint quoteBalance, bool isCall, uint addedAmount) internal view returns (uint utilizationRate) {
    utilizationRate = 100;
    if (isCall && baseBalance > 0) utilizationRate = (openInterestCalls + addedAmount) * 100 / baseBalance;
    else if (!isCall && quoteBalance > 0) utilizationRate = (openInterestPuts + addedAmount) * 100 / quoteBalance;
  }
  
  
  /// @notice Get highest utilization of both sides
  function getUtilizationRateStatus() public view returns (uint utilizationRate, uint maxOI) {
    (uint baseBalance, uint quoteBalance, ) = IGoodEntryVault(vault).getReserves();
    uint utilizationRateCall = baseBalance > 0 ? openInterestCalls * 100 / baseBalance : 0;
    uint utilizationRatePut = quoteBalance > 0 ? openInterestPuts * 100 / quoteBalance : 0;
    utilizationRate = utilizationRateCall > utilizationRatePut ? utilizationRateCall : utilizationRatePut;
    maxOI = MAX_UTILIZATION_RATE;
  }
  
  
  ///@notice Is it an emergency? openStrikes getting too long? allow closing deepest OTM positions
  function _isEmergencyStrike(uint strike) internal view returns (bool isEmergency) {
    if (openStrikes.length < MAX_OPEN_STRIKES || openStrikes.length < 2) return false;
    // Skip 1st entry which is 0
    uint minStrike = openStrikes[1];
    uint maxStrike = minStrike;
    // loop on all strikes
    for (uint k = 1; k < openStrikes.length; k++){
      if (openStrikes[k] > maxStrike) maxStrike = openStrikes[k];
      if (openStrikes[k] < minStrike) minStrike = openStrikes[k];
    }
    isEmergency = strike == maxStrike || strike == minStrike;
  }
  
  
  /// @notice Helper that checks current allowance and approves if necessary
  /// @param token Target token
  /// @param spender Spender
  /// @param amount Amount below which we need to approve the token spending
  function checkSetApprove(address token, address spender, uint amount) internal {
    uint currentAllowance = ERC20(token).allowance(address(this), spender);
    if (currentAllowance < amount) ERC20(token).safeIncreaseAllowance(spender, UINT256MAX - currentAllowance);
  }
  
  /// @notice Get the name of this contract token
  function name() public view virtual override(ERC721, IERC721Metadata) returns (string memory) { 
    return string(abi.encodePacked("GoodEntry Positions ", baseToken.symbol(), "-", quoteToken.symbol()));
  }
  /// @notice Get the symbol of this contract token
  function symbol() public view virtual override(ERC721, IERC721Metadata) returns (string memory _symbol) {
    _symbol = "Good-Trade";
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/IGoodEntryCore.sol";
import "../interfaces/IVaultConfigurator.sol";
import "../../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IWETH.sol";

abstract contract VaultConfigurator is Ownable {
  event SetFee(uint baseFeeX4);
  event SetTvlCap(uint tvlCapX8);
  event SetAmmPositionShare(uint8 ammPositionShareX2);


  /// @notice GoodEntry Core address
  IGoodEntryCore public goodEntryCore;
  /// @notice Pool base fee X4: 20 => 0.2%
  uint24 public baseFeeX4 = 20;
  // Useful to adjust fees down
  uint internal constant FEE_MULTIPLIER = 1e4;
  /// @notice Percentage of assets deployed in a full range
  uint8 public ammPositionShareX2 = 50;
  /// @notice Max vault TVL with 8 decimals, 0 for no limit
  uint96 public tvlCapX8;
  /// @notice WETH addrsss to handle ETH deposits
  IWETH internal WETH;
  // Obsolete but cant remove or will affect proxy storage stack
  mapping(address => uint) public depositTime;
  mapping(address => uint) public depositBalance;
  
  /// @notice initialize the value when a vault is created as a proxy
  function initializeConfig() internal {
    setBaseFee(20);
    setAmmPositionShare(50);
  }
  
  
  /// @notice Set ammPositionShare (how much of assets go into the AMM)
  /// @param _ammPositionShareX2 proportion of liquidity going into the AMM
  /// @dev Since liquidity is balanced between both assets, the share is taken according to lowest available token
  /// That share is therefore strictly lower that the TVL total
  function setAmmPositionShare(uint8 _ammPositionShareX2) public onlyOwner { 
    require(_ammPositionShareX2 <= 100, "VC: Invalid FRS");
    ammPositionShareX2 = _ammPositionShareX2; 
    emit SetAmmPositionShare(_ammPositionShareX2);
  }
  

  /// @notice Set the base fee
  /// @param _baseFeeX4 New base fee in E4, cant be > 100% = 1e4
  function setBaseFee(uint24 _baseFeeX4) public onlyOwner {
    require(_baseFeeX4 < FEE_MULTIPLIER, "VC: Invalid Base Fee");
    baseFeeX4 = _baseFeeX4;
    emit SetFee(_baseFeeX4);
  }
  
  
  /// @notice Set the TVL cap
  /// @param _tvlCapX8 New TVL cap
  function setTvlCap(uint96 _tvlCapX8) public onlyOwner {
    tvlCapX8 = _tvlCapX8;
    emit SetTvlCap(_tvlCapX8);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IGoodEntryOracle.sol";


/// @notice Commons for vaults and AMM positions for inheritance conflicts purposes
abstract contract GoodEntryCommons {
  /// @notice Vault underlying tokens
  ERC20 internal baseToken;
  ERC20 internal quoteToken;
  /// @notice Oracle address
  IGoodEntryOracle internal oracle;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


/**
 * @title FeeStreamer
 * @author GoodEntry
 * @dev Tracks fees accumulated for the current period, while streaming fees for the past period
 * The streamer doesnt actually holds funds, but account for the fees in a given period.
 * In practice, streaming is inverted: a contract call getPendingFees() to know how much of token balances are reserved
 */  
abstract contract FeeStreamer {
  event ReservedFees(uint value);
  
  /// @notice Streaming period in seconds, default daily
  uint internal constant streamingPeriod = 86400;
  /// @notice Fees accumated at a given period
  mapping (uint => uint) internal periodToFees0;
  mapping (uint => uint) internal periodToFees1;
  
  
  /// @notice Add fees to the current period
  function reserveFees(uint amount0, uint amount1, uint value) internal {
    uint period = block.timestamp / streamingPeriod;
    if(amount0 > 0) periodToFees0[period] += amount0;
    if(amount1 > 0) periodToFees1[period] += amount1;
    if(value > 0) emit ReservedFees(value);
  }
  
  
  /// @notice Returns amount of fees reserved, pending streaming
  function getPendingFees() public view returns (uint pendingFees0, uint pendingFees1) {
    // time elapsed in past period:
    uint currentPeriod = block.timestamp / streamingPeriod;
    uint remainingTime = streamingPeriod - block.timestamp % streamingPeriod;
    pendingFees0 = periodToFees0[currentPeriod] + periodToFees0[currentPeriod-1] * remainingTime / streamingPeriod;
    pendingFees1 = periodToFees1[currentPeriod] + periodToFees1[currentPeriod-1] * remainingTime / streamingPeriod;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IGoodEntryOracle.sol";
import "../interfaces/IGoodEntryVault.sol";
import "../GoodEntryCommons.sol";


abstract contract AmmPositionBase is GoodEntryCommons {
  using SafeERC20 for ERC20;
  
  /// EVENTS
  event ClaimFees(uint fee0, uint fee1);
  
  // Position parameters
  uint internal baseFees;
  uint internal quoteFees;
  
  uint128 constant UINT128MAX = type(uint128).max;
  uint256 constant UINT256MAX = type(uint256).max;

  
  /// @notice Checks whether AMM price and oracle price match
  /// @dev For a balanced pool (UniV2 or UniV3 full range), both tokens should be present in equal values by design
  function poolPriceMatchesOracle() public virtual returns (bool isMatching) {
    (uint baseAmount, uint quoteAmount) = _getReserves();
    uint baseValue = baseAmount * oracle.getAssetPrice(address(baseToken)) / 10**baseToken.decimals();
    uint quoteValue = quoteAmount * oracle.getAssetPrice(address(quoteToken)) / 10**quoteToken.decimals();
    isMatching = baseValue >= quoteValue * 99 / 100 && quoteValue >= baseValue * 99 / 100;
  }
  
    
  /// @notice Get lifetime fees
  function getLifetimeFees() public virtual view returns (uint, uint) {
    return (baseFees, quoteFees);
  }
  
  
  /// @notice Helper that checks current allowance and approves if necessary
  function checkSetApprove(address token, address spender, uint amount) internal {
    uint currentAllowance = ERC20(token).allowance(address(this), spender);
    if (currentAllowance < amount) ERC20(token).safeIncreaseAllowance(spender, UINT256MAX - currentAllowance);
  }
  
  
  function _getReserves() internal virtual view returns (uint baseAmount, uint quoteAmount) {}
  /// @notice Deposit assets and get exactly the expected liquidity
  /// @param baseAmount Amount of base asset
  /// @param quoteAmount Amount of quote asset
  /// @return liquidity Amount of LP tokens created
  function depositAmm(uint baseAmount, uint quoteAmount) internal virtual returns (uint liquidity);
  function withdrawAmm() internal virtual returns (uint baseAmount, uint quoteAmount);
  /// @notice Get ammType, for naming and tracking purposes
  function ammType() public pure virtual returns (bytes32 _ammType);
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967Upgrade is IERC1967 {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IGeNftDescriptor {
  struct ConstructTokenURIParams {
    uint256 tokenId;
    address quoteTokenAddress;
    address baseTokenAddress;
    string quoteTokenSymbol;
    string baseTokenSymbol;
    bool isCall;
    int pnl;
  }

  function constructTokenURI(ConstructTokenURIParams memory params) external view returns (string memory uri);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


import "../../node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IGoodEntryPositionManager is IERC721Metadata, IERC721Enumerable {  
  enum OptionType {FixedOption, StreamingOption}
  struct Position {
    bool isCall;
    /// @notice option type: 0: regular, 1: streaming
    OptionType optionType;
    uint strike;
    uint notionalAmount;
    uint collateralAmount;
    uint startDate;
    /// @dev if streaming option, this will be fundingRate, if fixed option: endDate
    uint data;
  }
  
  function initProxy(address _oracle, address _baseToken, address _quoteToken, address _vault, address _referrals) external;
  
  /*return (
      MIN_POSITION_VALUE_X8, 
      MIN_COLLATERAL_AMOUNT, 
      FIXED_EXERCISE_FEE, 
      STREAMING_OPTION_TTE, 
      MIN_FIXED_OPTIONS_TTE, 
      MAX_FIXED_OPTIONS_TTE, 
      MAX_UTILIZATION_RATE, 
      MAX_STRIKE_DISTANCE_X2,
      MIN_ELAPSED_DURATION
    );*/
  function getParameters() external view returns (uint, uint, uint, uint, uint, uint, uint8, uint8, uint);
  function vault() external returns (address);
  function openStrikes(uint) external returns (uint);
  function getOpenStrikesLength() external returns (uint);
  function getPosition(uint tokenId) external view returns (Position memory);
  //function openFixedPosition(bool isCall, uint strike, uint notionalAmount, uint endDate) external returns (uint tokenId);
  //function openStreamingPosition(bool isCall, uint notionalAmount, uint collateralAmount) external returns (uint tokenId);
  //function closePosition(uint tokenId) external;
  function getFeesAccumulated(uint tokenId) external view returns (uint feesAccumulated);
  function getFeesAccumulatedAndMin(uint tokenId) external view returns (uint feesAccumulated, uint feesMin);
  function getValueAtStrike(bool isCall, uint price, uint strike, uint amount) external pure returns (uint vaultDue, uint pnl);
  function getAssetsDue() external view returns (uint baseAmount, uint quoteAmount);
  function getOptionPrice(bool isCall, uint strike, uint size, uint timeToExpirySec) external view returns (uint optionPriceX8);
  function strikeToOpenInterestCalls(uint strike) external view returns (uint);
  function strikeToOpenInterestPuts(uint strike) external view returns (uint);
  function getUtilizationRateStatus() external view returns (uint utilizationRate, uint maxOI);
  function getUtilizationRate(bool isCall, uint addedAmount) external view returns (uint utilizationRate);
  //function increaseCollateral(uint tokenId, uint newCollateralAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/IGoodEntryCore.sol";


interface IVaultConfigurator  {
  function goodEntryCore() external returns (IGoodEntryCore);
  function baseFeeX4() external returns (uint24);
  function owner() external returns (address);
  function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


interface IGoodEntryCore {
  function treasury() external returns (address);
  function treasuryShareX2() external returns (uint8);
  function setTreasury(address _treasury, uint8 _treasuryShareX2) external;
  function updateReferrals(address _referrals) external;
  function isPaused() external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IReferrals {
  function registerName(bytes32 name) external;
  function registerReferrer(bytes32 name) external;
  function getReferrer(address user) external view returns (address referrer);
  function getRefereesLength(address referrer) external view returns (uint length);
  function getReferee(address referrer, uint index) external view returns (address referee);
  function getReferralParameters(address user) external view returns (address referrer, uint16 rebateReferrer, uint16 discountReferee);
  function addVipNft(address _nft) external;
  function removeVipNft(address _nft) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


/// @title Range middleware between ROE lending pool and various ranges
library StrikeManager {
 
  /// @notice Get price strike psacing based on price
  function getStrikeSpacing(uint price) public pure returns (uint) {
    // price is X8 so at that point it makes no much sense anyway, meme tokens like PEPE not supported
    if (price < 500) return 1;
    else if(price >= 500 && price < 1000) return 2;
    else  // price > 1000 (x8)
      return getStrikeSpacing(price / 10) * 10;
  }
  

  /// @notice Get the closest strike strictly above price
  function getStrikeStrictlyAbove(uint price) public pure returns (uint strike) {
    uint strikeSpacing = getStrikeSpacing(price);
    strike = price - price % strikeSpacing + strikeSpacing;
  }
  
  
  /// @notice Get the strike equal or above price
  function getStrikeAbove(uint price) public pure returns (uint strike) {
    uint strikeSpacing = getStrikeSpacing(price);
    strike = (price % strikeSpacing == 0) ? price : price - price % strikeSpacing + strikeSpacing;
  }


  /// @notice Gets strike equal or below 
  function getStrikeBelow(uint price) public pure returns (uint strike){
    uint strikeSpacing = getStrikeSpacing(price);
    strike = price - price % strikeSpacing;
  }
  
  
  /// @notice Get the closest strike strictly below price
  function getStrikeStrictlyBelow(uint price) public pure returns (uint strike) {
    uint strikeSpacing = getStrikeSpacing(price);
    if (price % strikeSpacing == 0) {
      // for the tick below, the tick spacing isnt the same, therefore if price is exactly on the tick, 
      // we need to query a slightly below price to get the proper spacing
      strikeSpacing = getStrikeSpacing(price - 1);
      strike = price - strikeSpacing;
    }
    else strike = price - price % strikeSpacing;
  }
  

  /// @notice Check if strike is valid
  function isValidStrike(uint strike) public pure returns (bool isValid) {
    uint strikeSpacing = getStrikeSpacing(strike);
    return strike > 0 && strike % strikeSpacing == 0;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IWETH {
  function deposit() external payable;
  function balanceOf(address) external view returns (uint);
  function transfer(address to, uint value) external returns (bool);
  function withdraw(uint) external;
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IAaveOracle} from "../lib/AaveOracle/IAaveOracle.sol";

/**
 * @title IGoodEntryOracle
 * @author GoodEntry
 * @notice Defines the basic interface for the Oracle, based on Aave Oracle
 */
interface IGoodEntryOracle is IAaveOracle{
  /**
   * @notice Returns the volatility of an asset address
   * @param asset The address of the asset
   * @param length The length in days used for the calculation, no more than 30 days
   * @return volatility The realized volatility of the asset as observed by the oracle X8 (100% = 1e8)
   * @dev Purely indicative and unreliable
   */
  function getAssetVolatility(address asset, uint8 length) external view returns (uint224 volatility);
  
  /// @notice Returns the risk free rate of money markets X8
  function getRiskFreeRate() external view returns (int256);
  /// @notice Sets the risk free rate of money markets
  function setRiskFreeRate(int256 riskFreeRate) external;
  /**
   * @dev Emitted after the risk-free rate is updated
   * @param riskFreeRate The risk free rate
   */
  event RiskFreeRateUpdated(int256 riskFreeRate);
  
  
  /// @notice Returns the risk free rate of money markets X8
  function getIVMultiplier() external view returns (uint16);
  /// @notice Sets the risk free rate of money markets
  function setIVMultiplier(uint16 ivMultiplier) external;
  /// @notice Emitted after the IV multiplier is updated
  event IVMultiplierUpdated(uint16 ivMultiplier);
  
  /**
   * @notice Updates a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @dev prices can be updated once daily for volatility calculation
   */
  function snapshotDailyAssetsPrices(address[] calldata assets) external;
  /**
   * @notice Gets the price of an asset at a given day
   * @param asset The asset address
   * @param thatDay The day, expressed in days since 1970, today is block.timestamp / 86400
   */
  function getAssetPriceAtDay(address asset, uint thatDay) external view returns (uint256);
  
  /**
   * @notice Gets the price of an option based on strike, tte and utilization rate
   */
  function getOptionPrice(bool isCall, address baseToken, address quoteToken, uint strike, uint timeToExpirySec, uint utilizationRateX8) 
    external view returns (uint optionPriceX8);
    
  /// @notice Get the price of an option based on BS parameters and utilization rate
  function getOptionPrice(bool isCall, address baseToken, address quoteToken, uint strike, uint timeToExpirySec, uint volatility, uint utilizationRate)
    external view returns (uint callPrice, uint putPrice);
    
  /// @notice Get the adjusted volatility for an asset over 10d, used in option pricing with IV premium over HV
  function getAdjustedVolatility(address baseToken, uint utilizationRate) external view returns (uint volatility);
}

pragma solidity >=0.6.2;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPriceOracleGetter} from './IPriceOracleGetter.sol';
import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';

/**
 * @title IAaveOracle
 * @author Aave
 * @notice Defines the basic interface for the Aave Oracle
 */
interface IAaveOracle is IPriceOracleGetter {
  /**
   * @dev Emitted after the base currency is set
   * @param baseCurrency The base currency of used for price quotes
   * @param baseCurrencyUnit The unit of the base currency
   */
  event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);

  /**
   * @dev Emitted after the price source of an asset is updated
   * @param asset The address of the asset
   * @param source The price source of the asset
   */
  event AssetSourceUpdated(address indexed asset, address indexed source);

  /**
   * @dev Emitted after the address of fallback oracle is updated
   * @param fallbackOracle The address of the fallback oracle
   */
  event FallbackOracleUpdated(address indexed fallbackOracle);

  /**
   * @notice Returns the PoolAddressesProvider
   * @return The address of the PoolAddressesProvider contract
   */
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Sets or replaces price sources of assets
   * @param assets The addresses of the assets
   * @param sources The addresses of the price sources
   */
  function setAssetSources(address[] calldata assets, address[] calldata sources) external;

  /**
   * @notice Sets the fallback oracle
   * @param fallbackOracle The address of the fallback oracle
   */
  function setFallbackOracle(address fallbackOracle) external;

  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
  function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

  /**
   * @notice Returns the address of the source for an asset address
   * @param asset The address of the asset
   * @return The address of the source
   */
  function getSourceOfAsset(address asset) external view returns (address);

  /**
   * @notice Returns the address of the fallback oracle
   * @return The address of the fallback oracle
   */
  function getFallbackOracle() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPriceOracleGetter
 * @author Aave
 * @notice Interface for the Aave price oracle.
 */
interface IPriceOracleGetter {
  /**
   * @notice Returns the base currency address
   * @dev Address 0x0 is reserved for USD as base currency.
   * @return Returns the base currency address.
   */
  function BASE_CURRENCY() external view returns (address);

  /**
   * @notice Returns the base currency unit
   * @dev 1 ether for ETH, 1e8 for USD.
   * @return Returns the base currency unit.
   */
  function BASE_CURRENCY_UNIT() external view returns (uint256);

  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   */
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 */
interface IPoolAddressesProvider {
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL admin is updated.
   * @param oldAddress The old address of the ACLAdmin
   * @param newAddress The new address of the ACLAdmin
   */
  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle sentinel is updated.
   * @param oldAddress The old address of the PriceOracleSentinel
   * @param newAddress The new address of the PriceOracleSentinel
   */
  event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Aave market to which this contract points to.
   * @return The market id
   */
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Aave markets.
   * @param newMarketId The market id
   */
  function setMarketId(string calldata newMarketId) external;

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address might be an EOA or a contract, potentially proxied
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `newImplementationAddress`.
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param newImplementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   */
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   */
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   */
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   */
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

  /**
   * @notice Returns the address of the price oracle.
   * @return The address of the PriceOracle
   */
  function getPriceOracle() external view returns (address);

  /**
   * @notice Updates the address of the price oracle.
   * @param newPriceOracle The address of the new PriceOracle
   */
  function setPriceOracle(address newPriceOracle) external;

  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACL manager.
   * @param newAclManager The address of the new ACLManager
   */
  function setACLManager(address newAclManager) external;

  /**
   * @notice Returns the address of the ACL admin.
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin.
   * @param newAclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address newAclAdmin) external;

  /**
   * @notice Returns the address of the price oracle sentinel.
   * @return The address of the PriceOracleSentinel
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the price oracle sentinel.
   * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
   */
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   */
  function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

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