// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {CoreRef} from "@src/core/CoreRef.sol";
import {CoreRoles} from "@src/core/CoreRoles.sol";
import {LendingTerm} from "@src/loan/LendingTerm.sol";
import {CreditToken} from "@src/tokens/CreditToken.sol";
import {ProfitManager} from "@src/governance/ProfitManager.sol";

/// @notice Simple PSM contract of the Ethereum Credit Guild, that allows mint/redeem
/// of CREDIT token outside of lending terms & guarantee a stable peg of the CREDIT token
/// around the value targeted by the protocol.
/// The SimplePSM targets a value equal to ProfitManager.creditMultiplier(), so when bad
/// debt is created and all loans are marked up, they stay the same in terms of peg token,
/// because new CREDIT can be minted with fewer peg tokens from the PSM. Conversely, when
/// new loans are issued, if there are funds available in the SimplePSM, borrowers know
/// the amount of peg tokens they'll be able to redeem their borrowed CREDIT for.
/// @dev inspired by the SimpleFeiDaiPSM used in the TribeDAO shutdown, see:
/// - https://github.com/code-423n4/2022-09-tribe/blob/main/contracts/peg/SimpleFeiDaiPSM.sol
/// - https://code4rena.com/reports/2022-09-tribe
contract SimplePSM is CoreRef {
    using SafeERC20 for ERC20;

    /// @notice reference to the ProfitManager contract
    address public immutable profitManager;

    /// @notice reference to the CreditToken contract
    address public immutable credit;

    /// @notice reference to the peg token contract
    address public immutable pegToken;

    /// @notice peg token balance, used to track sum of i/o and exclude donations.
    /// invariant: pegToken.balanceOf(this) >= pegTokenBalance
    uint256 public pegTokenBalance;

    /// @notice multiplier for decimals correction, e.g. 1e12 for a pegToken
    /// with 6 decimals (because CREDIT has 18 decimals)
    uint256 public immutable decimalCorrection;

    /// @notice true if the redemptions are currently paused
    bool public redemptionsPaused;

    /// @notice event emitted upon a redemption
    event Redeem(
        uint256 indexed when,
        address indexed to,
        uint256 amountIn,
        uint256 amountOut
    );
    /// @notice event emitted when credit gets minted
    event Mint(
        uint256 indexed when,
        address indexed to,
        uint256 amountIn,
        uint256 amountOut
    );
    /// @notice event emitted when redemption pausability status changes
    event RedemptionsPaused(uint256 indexed when, bool status);

    constructor(
        address _core,
        address _profitManager,
        address _credit,
        address _pegToken
    ) CoreRef(_core) {
        profitManager = _profitManager;
        credit = _credit;
        pegToken = _pegToken;

        /// @dev note that peg tokens with more than 18 decimals are not
        /// supported and will revert on PSM deploy.
        uint256 decimals = uint256(ERC20(_pegToken).decimals());
        decimalCorrection = 10 ** (18 - decimals);
    }

    /// @notice calculate the amount of CREDIT out for a given `amountIn` of underlying
    function getMintAmountOut(uint256 amountIn) public view returns (uint256) {
        uint256 creditMultiplier = ProfitManager(profitManager)
            .creditMultiplier();
        return (amountIn * decimalCorrection * 1e18) / creditMultiplier;
    }

    /// @notice calculate the amount of underlying out for a given `amountIn` of CREDIT
    function getRedeemAmountOut(
        uint256 amountIn
    ) public view returns (uint256) {
        uint256 creditMultiplier = ProfitManager(profitManager)
            .creditMultiplier();
        return (amountIn * creditMultiplier) / 1e18 / decimalCorrection;
    }

    /// @notice calculate the total number of CREDIT that can be redeemed
    /// at the moment, based on the pegTokenBalance.
    function redeemableCredit() public view returns (uint256) {
        return getMintAmountOut(pegTokenBalance);
    }

    /// @notice mint `amountOut` CREDIT to address `to` for `amountIn` underlying tokens
    /// @dev see getMintAmountOut() to pre-calculate amount out
    function mint(
        address to,
        uint256 amountIn
    ) external whenNotPaused returns (uint256 amountOut) {
        amountOut = getMintAmountOut(amountIn);
        pegTokenBalance += amountIn;
        ERC20(pegToken).safeTransferFrom(msg.sender, address(this), amountIn);
        CreditToken(credit).mint(to, amountOut);
        emit Mint(block.timestamp, to, amountIn, amountOut);
    }

    /// @notice mint `amountOut` CREDIT to `msg.sender` for `amountIn` underlying tokens
    /// and enter rebase to earn the savings rate.
    /// @dev see getMintAmountOut() to pre-calculate amount out
    function mintAndEnterRebase(
        uint256 amountIn
    ) external whenNotPaused returns (uint256 amountOut) {
        require(
            !CreditToken(credit).isRebasing(msg.sender),
            "SimplePSM: already rebasing"
        );
        amountOut = getMintAmountOut(amountIn);
        pegTokenBalance += amountIn;
        ERC20(pegToken).safeTransferFrom(msg.sender, address(this), amountIn);
        CreditToken(credit).mint(msg.sender, amountOut);
        CreditToken(credit).forceEnterRebase(msg.sender);
        emit Mint(block.timestamp, msg.sender, amountIn, amountOut);
    }

    /// @notice redeem `amountIn` CREDIT for `amountOut` underlying tokens and send to address `to`
    /// @dev see getRedeemAmountOut() to pre-calculate amount out
    function redeem(
        address to,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        require(!redemptionsPaused, "SimplePSM: redemptions paused");
        amountOut = getRedeemAmountOut(amountIn);
        pegTokenBalance -= amountOut;
        CreditToken(credit).burnFrom(msg.sender, amountIn);
        ERC20(pegToken).safeTransfer(to, amountOut);
        emit Redeem(block.timestamp, to, amountIn, amountOut);
    }

    /// @notice set `redemptionsPaused`
    /// governor-only, to allow full governance to update the psm mechanisms,
    /// or automated processes to pause redemptions under certain conditions.
    function setRedemptionsPaused(
        bool paused
    ) external onlyCoreRole(CoreRoles.GOVERNOR) {
        redemptionsPaused = paused;
        emit RedemptionsPaused(block.timestamp, paused);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {Core} from "@src/core/Core.sol";
import {CoreRoles} from "@src/core/CoreRoles.sol";

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

/// @title A Reference to Core
/// @author eswak
/// @notice defines some modifiers and utilities around interacting with Core
abstract contract CoreRef is Pausable {
    /// @notice emitted when the reference to core is updated
    event CoreUpdate(address indexed oldCore, address indexed newCore);

    /// @notice reference to Core
    Core private _core;

    constructor(address coreAddress) {
        _core = Core(coreAddress);
    }

    /// @notice named onlyCoreRole to prevent collision with OZ onlyRole modifier
    modifier onlyCoreRole(bytes32 role) {
        require(_core.hasRole(role, msg.sender), "UNAUTHORIZED");
        _;
    }

    /// @notice address of the Core contract referenced
    function core() public view returns (Core) {
        return _core;
    }

    /// @notice WARNING CALLING THIS FUNCTION CAN POTENTIALLY
    /// BRICK A CONTRACT IF CORE IS SET INCORRECTLY
    /// @notice set new reference to core
    /// only callable by governor
    /// @param newCore to reference
    function setCore(
        address newCore
    ) external onlyCoreRole(CoreRoles.GOVERNOR) {
        _setCore(newCore);
    }

    /// @notice WARNING CALLING THIS FUNCTION CAN POTENTIALLY
    /// BRICK A CONTRACT IF CORE IS SET INCORRECTLY
    /// @notice set new reference to core
    /// @param newCore to reference
    function _setCore(address newCore) internal {
        address oldCore = address(_core);
        _core = Core(newCore);

        emit CoreUpdate(oldCore, newCore);
    }

    /// @notice set pausable methods to paused
    function pause() public onlyCoreRole(CoreRoles.GUARDIAN) {
        _pause();
    }

    /// @notice set pausable methods to unpaused
    function unpause() public onlyCoreRole(CoreRoles.GUARDIAN) {
        _unpause();
    }

    /// ------------------------------------------
    /// ------------ Emergency Action ------------
    /// ------------------------------------------

    /// inspired by MakerDAO Multicall:
    /// https://github.com/makerdao/multicall/blob/master/src/Multicall.sol

    /// @notice struct to pack calldata and targets for an emergency action
    struct Call {
        /// @notice target address to call
        address target;
        /// @notice amount of eth to send with the call
        uint256 value;
        /// @notice payload to send to target
        bytes callData;
    }

    /// @notice due to inflexibility of current smart contracts,
    /// add this ability to be able to execute arbitrary calldata
    /// against arbitrary addresses.
    /// callable only by governor
    function emergencyAction(
        Call[] calldata calls
    )
        external
        payable
        onlyCoreRole(CoreRoles.GOVERNOR)
        returns (bytes[] memory returnData)
    {
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            address payable target = payable(calls[i].target);
            uint256 value = calls[i].value;
            bytes calldata callData = calls[i].callData;

            (bool success, bytes memory returned) = target.call{value: value}(
                callData
            );
            require(success, "CoreRef: underlying call reverted");
            returnData[i] = returned;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

/**
@title Ethereum Credit Guild ACL Roles
@notice Holds a complete list of all roles which can be held by contracts inside the Ethereum Credit Guild.
*/
library CoreRoles {
    /// ----------- Core roles for access control --------------

    /// @notice the all-powerful role. Controls all other roles and protocol functionality.
    bytes32 internal constant GOVERNOR = keccak256("GOVERNOR_ROLE");

    /// @notice the protector role. Can pause contracts and revoke roles in an emergency.
    bytes32 internal constant GUARDIAN = keccak256("GUARDIAN_ROLE");

    /// ----------- Token supply roles -------------------------

    /// @notice can mint CREDIT arbitrarily
    bytes32 internal constant CREDIT_MINTER = keccak256("CREDIT_MINTER_ROLE");

    /// @notice can burn CREDIT tokens
    bytes32 internal constant CREDIT_BURNER = keccak256("CREDIT_BURNER_ROLE");

    /// @notice can mint CREDIT within rate limits & cap
    bytes32 internal constant RATE_LIMITED_CREDIT_MINTER =
        keccak256("RATE_LIMITED_CREDIT_MINTER_ROLE");

    /// @notice can mint GUILD arbitrarily
    bytes32 internal constant GUILD_MINTER = keccak256("GUILD_MINTER_ROLE");

    /// @notice can mint GUILD within rate limits & cap
    bytes32 internal constant RATE_LIMITED_GUILD_MINTER =
        keccak256("RATE_LIMITED_GUILD_MINTER_ROLE");

    /// ----------- GUILD Token Management ---------------

    /// @notice can manage add new gauges to the system
    bytes32 internal constant GAUGE_ADD = keccak256("GAUGE_ADD_ROLE");

    /// @notice can remove gauges from the system
    bytes32 internal constant GAUGE_REMOVE = keccak256("GAUGE_REMOVE_ROLE");

    /// @notice can manage gauge parameters (max gauges, individual cap)
    bytes32 internal constant GAUGE_PARAMETERS =
        keccak256("GAUGE_PARAMETERS_ROLE");

    /// @notice can notify of profits & losses in a given gauge
    bytes32 internal constant GAUGE_PNL_NOTIFIER =
        keccak256("GAUGE_PNL_NOTIFIER_ROLE");

    /// @notice can update governance parameters for GUILD delegations
    bytes32 internal constant GUILD_GOVERNANCE_PARAMETERS =
        keccak256("GUILD_GOVERNANCE_PARAMETERS_ROLE");

    /// @notice can withdraw from GUILD surplus buffer
    bytes32 internal constant GUILD_SURPLUS_BUFFER_WITHDRAW =
        keccak256("GUILD_SURPLUS_BUFFER_WITHDRAW_ROLE");

    /// ----------- CREDIT Token Management ---------------

    /// @notice can update governance parameters for CREDIT delegations
    bytes32 internal constant CREDIT_GOVERNANCE_PARAMETERS =
        keccak256("CREDIT_GOVERNANCE_PARAMETERS_ROLE");

    /// @notice can update rebase parameters for CREDIT holders
    bytes32 internal constant CREDIT_REBASE_PARAMETERS =
        keccak256("CREDIT_REBASE_PARAMETERS_ROLE");

    /// ----------- Timelock management ------------------------
    /// The hashes are the same as OpenZeppelins's roles in TimelockController

    /// @notice can propose new actions in timelocks
    bytes32 internal constant TIMELOCK_PROPOSER = keccak256("PROPOSER_ROLE");

    /// @notice can execute actions in timelocks after their delay
    bytes32 internal constant TIMELOCK_EXECUTOR = keccak256("EXECUTOR_ROLE");

    /// @notice can cancel actions in timelocks
    bytes32 internal constant TIMELOCK_CANCELLER = keccak256("CANCELLER_ROLE");
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

import {CoreRef} from "@src/core/CoreRef.sol";
import {CoreRoles} from "@src/core/CoreRoles.sol";
import {GuildToken} from "@src/tokens/GuildToken.sol";
import {CreditToken} from "@src/tokens/CreditToken.sol";
import {AuctionHouse} from "@src/loan/AuctionHouse.sol";
import {ProfitManager} from "@src/governance/ProfitManager.sol";
import {RateLimitedMinter} from "@src/rate-limits/RateLimitedMinter.sol";

/// @notice Lending Term contract of the Ethereum Credit Guild, a base implementation of
/// smart contract issuing CREDIT debt and escrowing collateral assets.
/// Note that interest rate is non-compounding and the percentage is expressed per
/// period of `YEAR` seconds.
contract LendingTerm is CoreRef {
    using SafeERC20 for IERC20;

    // events for the lifecycle of loans that happen in the lending term
    /// @notice emitted when new loans are opened (mint debt to borrower, pull collateral from borrower).
    event LoanOpen(
        uint256 indexed when,
        bytes32 indexed loanId,
        address indexed borrower,
        uint256 collateralAmount,
        uint256 borrowAmount
    );
    /// @notice emitted when a loan is called.
    event LoanCall(uint256 indexed when, bytes32 indexed loanId);
    /// @notice emitted when a loan is closed (repay, onBid after a call, forgive).
    enum LoanCloseType {
        Repay,
        Call,
        Forgive
    }
    event LoanClose(
        uint256 indexed when,
        bytes32 indexed loanId,
        LoanCloseType indexed closeType,
        uint256 debtRepaid
    );
    /// @notice emitted when someone adds collateral to a loan
    event LoanAddCollateral(
        uint256 indexed when,
        bytes32 indexed loanId,
        address indexed borrower,
        uint256 collateralAmount
    );
    /// @notice emitted when someone partially repays a loan
    event LoanPartialRepay(
        uint256 indexed when,
        bytes32 indexed loanId,
        address indexed repayer,
        uint256 repayAmount
    );
    /// @notice emitted when the auctionHouse reference is updated
    event SetAuctionHouse(uint256 indexed when, address auctionHouse);
    /// @notice emitted when the hardCap is updated
    event SetHardCap(uint256 indexed when, uint256 hardCap);

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice Reference number of seconds per periods in which the interestRate is expressed.
    /// This is equal to 365.25 days.
    uint256 public constant YEAR = 31557600;

    struct Loan {
        address borrower; // address of a loan's borrower
        uint48 borrowTime; // the time the loan was initiated
        uint48 lastPartialRepay; // the time of last partial repay
        uint256 borrowAmount; // initial CREDIT debt of a loan
        uint256 borrowCreditMultiplier; // creditMultiplier when loan was opened
        uint256 collateralAmount; // balance of collateral token provided by the borrower
        address caller; // a caller of 0 indicates that the loan has not been called
        uint48 callTime; // a call time of 0 indicates that the loan has not been called
        uint48 closeTime; // the time the loan was closed (repaid or call+bid or forgive)
        uint256 callDebt; // the CREDIT debt when the loan was called
    }

    /// @notice the list of all loans that existed or are still active.
    /// @dev see public getLoan(loanId) getter.
    mapping(bytes32 => Loan) internal loans;

    /// @notice current number of CREDIT issued in active loans on this term
    /// @dev this can be lower than the sum of all loan's CREDIT debts because
    /// interests accrue and some loans might have been opened before the creditMultiplier
    /// was last updated, resulting in higher CREDIT debt than what was originally borrowed.
    uint256 public issuance;

    struct LendingTermReferences {
        /// @notice reference to the ProfitManager
        address profitManager;
        /// @notice reference to the GUILD token
        address guildToken;
        /// @notice reference to the auction house contract used to
        /// sell loan collateral for CREDIT if loans are called.
        address auctionHouse;
        /// @notice reference to the credit minter contract
        address creditMinter;
        /// @notice reference to the CREDIT token
        address creditToken;
    }

    /// @notice References to other protocol contracts (see struct for more details)
    LendingTermReferences internal refs;

    struct LendingTermParams {
        /// @notice reference to the collateral token
        address collateralToken;
        /// @notice max number of debt tokens issued per collateral token.
        /// @dev be mindful of the decimals here, because if collateral
        /// token doesn't have 18 decimals, this variable is used to scale
        /// the decimals.
        /// For example, for USDC collateral, this variable should be around
        /// ~1e30, to allow 1e6 * 1e30 / 1e18 ~= 1e18 CREDIT to be borrowed for
        /// each 1e6 units (1 USDC) of collateral, if CREDIT is targeted to be
        /// worth around 1 USDC.
        uint256 maxDebtPerCollateralToken;
        /// @notice interest rate paid by the borrower, expressed as an APR
        /// with 18 decimals (0.01e18 = 1% APR). The base for 1 year is the YEAR constant.
        uint256 interestRate;
        /// @notice maximum delay, in seconds, between partial debt repayments.
        /// if set to 0, no periodic partial repayments are expected.
        /// if a partial repayment is missed (delay has passed), the loan
        /// can be called.
        uint256 maxDelayBetweenPartialRepay;
        /// @notice minimum percent of the total debt (principal + interests) to
        /// repay during partial debt repayments.
        /// percentage is expressed with 18 decimals, e.g. 0.05e18 = 5% debt.
        uint256 minPartialRepayPercent;
        /// @notice the opening fee is a percent of interest that instantly accrues
        /// when the loan is opened.
        /// The opening fee is expressed as a percentage of the borrowAmount, with 18
        /// decimals, e.g. 0.05e18 = 5% of the borrowed amount.
        /// A loan with 2% openingFee and 3% interestRate will owe 102% of the borrowed
        /// amount just after being open, and after 1 year will owe 105%.
        uint256 openingFee;
        /// @notice the absolute maximum amount of debt this lending term can issue
        /// at any given time, regardless of the gauge allocations.
        uint256 hardCap;
    }

    /// @notice Params of the LendingTerm (see struct for more details)
    LendingTermParams internal params;

    constructor() CoreRef(address(1)) {
        // core is set to address(1) to prevent implementation from being initialized,
        // only proxies on the implementation can be initialized.
    }

    /// @notice initialize storage with references to other protocol contracts
    /// and the lending term parameters for this instance.
    function initialize(
        address _core,
        LendingTermReferences calldata _refs,
        bytes calldata _params
    ) external {
        // can initialize only once
        assert(address(core()) == address(0));
        assert(_core != address(0));

        // initialize storage
        _setCore(_core);
        refs = _refs;
        params = abi.decode(_params, (LendingTermParams));

        // check parameters:
        // must be an ERC20 (maybe, at least it prevents dumb input mistakes)
        (bool success, bytes memory returned) = params.collateralToken.call(
            abi.encodeWithSelector(IERC20.totalSupply.selector)
        );
        require(
            success && returned.length == 32,
            "LendingTerm: invalid collateralToken"
        );

        require(
            params.maxDebtPerCollateralToken != 0, // must be able to mint non-zero debt
            "LendingTerm: invalid maxDebtPerCollateralToken"
        );

        require(
            params.interestRate < 1e18, // interest rate [0, 100[% APR
            "LendingTerm: invalid interestRate"
        );

        require(
            params.maxDelayBetweenPartialRepay < YEAR + 1, // periodic payment every [0, 1 year]
            "LendingTerm: invalid maxDelayBetweenPartialRepay"
        );

        require(
            params.minPartialRepayPercent < 1e18, // periodic payment sizes [0, 100[%
            "LendingTerm: invalid minPartialRepayPercent"
        );

        require(
            params.openingFee <= 0.1e18, // open fee expected [0, 10]%
            "LendingTerm: invalid openingFee"
        );

        require(
            params.hardCap != 0, // non-zero hardcap
            "LendingTerm: invalid hardCap"
        );

        // if one of the periodic payment parameter is used, both must be used
        if (
            params.minPartialRepayPercent != 0 ||
            params.maxDelayBetweenPartialRepay != 0
        ) {
            require(
                params.minPartialRepayPercent != 0 &&
                    params.maxDelayBetweenPartialRepay != 0,
                "LendingTerm: invalid periodic payment params"
            );
        }

        // events
        emit SetAuctionHouse(block.timestamp, _refs.auctionHouse);
        emit SetHardCap(block.timestamp, params.hardCap);
    }

    /// @notice get references of this term to other protocol contracts
    function getReferences()
        external
        view
        returns (LendingTermReferences memory)
    {
        return refs;
    }

    /// @notice get parameters of this term
    function getParameters() external view returns (LendingTermParams memory) {
        return params;
    }

    /// @notice get parameter 'collateralToken' of this term
    function collateralToken() external view returns (address) {
        return params.collateralToken;
    }

    /// @notice get reference 'profitManager' of this term
    function profitManager() external view returns (address) {
        return refs.profitManager;
    }

    /// @notice get reference 'creditToken' of this term
    function creditToken() external view returns (address) {
        return refs.creditToken;
    }

    /// @notice get reference 'auctionHouse' of this term
    function auctionHouse() external view returns (address) {
        return refs.auctionHouse;
    }

    /// @notice get a loan
    function getLoan(bytes32 loanId) external view returns (Loan memory) {
        return loans[loanId];
    }

    /// @notice outstanding borrowed amount of a loan, including interests
    function getLoanDebt(bytes32 loanId) public view returns (uint256) {
        uint256 creditMultiplier = ProfitManager(refs.profitManager)
            .creditMultiplier();
        return _getLoanDebt(loanId, creditMultiplier);
    }

    /// @notice outstanding borrowed amount of a loan, including interests,
    /// given a creditMultiplier
    function _getLoanDebt(
        bytes32 loanId,
        uint256 creditMultiplier
    ) internal view returns (uint256) {
        Loan storage loan = loans[loanId];
        uint256 borrowTime = loan.borrowTime;

        if (borrowTime == 0) {
            return 0;
        }

        if (loan.closeTime != 0) {
            return 0;
        }

        if (loan.callTime != 0) {
            return loan.callDebt;
        }

        // compute interest owed
        uint256 borrowAmount = loan.borrowAmount;
        uint256 interest = (borrowAmount *
            params.interestRate *
            (block.timestamp - borrowTime)) /
            YEAR /
            1e18;
        uint256 loanDebt = borrowAmount + interest;
        uint256 _openingFee = params.openingFee;
        if (_openingFee != 0) {
            loanDebt += (borrowAmount * _openingFee) / 1e18;
        }
        loanDebt = (loanDebt * loan.borrowCreditMultiplier) / creditMultiplier;

        return loanDebt;
    }

    /// @notice maximum debt for a given amount of collateral
    function maxDebtForCollateral(
        uint256 collateralAmount
    ) public view returns (uint256) {
        uint256 creditMultiplier = ProfitManager(refs.profitManager)
            .creditMultiplier();
        return _maxDebtForCollateral(collateralAmount, creditMultiplier);
    }

    /// @notice maximum debt for a given amount of collateral & creditMultiplier
    function _maxDebtForCollateral(
        uint256 collateralAmount,
        uint256 creditMultiplier
    ) internal view returns (uint256) {
        return
            (collateralAmount * params.maxDebtPerCollateralToken) /
            creditMultiplier;
    }

    /// @notice returns true if the term has a maximum delay between partial repays
    /// and the loan has passed the delay for partial repayments.
    function partialRepayDelayPassed(
        bytes32 loanId
    ) public view returns (bool) {
        // if no periodic partial repays are expected, always return false
        if (params.maxDelayBetweenPartialRepay == 0) return false;

        // if loan doesn't exist, return false
        if (loans[loanId].borrowTime == 0) return false;

        // if loan is closed, return false
        if (loans[loanId].closeTime != 0) return false;

        // return true if delay is passed
        return
            loans[loanId].lastPartialRepay <
            block.timestamp - params.maxDelayBetweenPartialRepay;
    }

    /// @notice returns the maximum amount of debt that can be issued by this term
    /// according to the current gauge allocations.
    /// Note that the debt ceiling can be lower than the current issuance under 2 conditions :
    /// - gauge votes are fewer than when last borrow happened (in % relative to other terms)
    /// - profitManager.totalIssuance() decreased since last borrow
    /// Note that borrowing term.debtCeiling() - term.issuance() could still revert if the
    /// credit minter buffer is not enough to mint the borrowAmount, or if the term's hardCap
    /// is set to a lower value than the debt ceiling.
    /// @dev this solves the following equation :
    /// borrowAmount + issuance <=
    /// (totalIssuance + borrowAmount) * gaugeWeight * gaugeWeightTolerance / totalWeight / 1e18
    /// which is the formula to check debt ceiling in the borrow function.
    /// This equation gives the maximum borrowable amount to achieve 100% utilization of the debt
    /// ceiling, and if we add the current issuance to it, we get the current debt ceiling.
    /// @param gaugeWeightDelta an hypothetical change in gauge weight
    /// @return the maximum amount of debt that can be issued by this term
    function debtCeiling(
        int256 gaugeWeightDelta
    ) public view returns (uint256) {
        address _guildToken = refs.guildToken; // cached SLOAD
        // if the term is deprecated, return 0 debtCeiling
        if (!GuildToken(_guildToken).isGauge(address(this))) {
            // intended side effect: if the gauge is deprecated, wait that all loans
            // are closed (liquidation auctions conclude) before allowing GUILD token
            // holders to decrement weight.
            return 0;
        }
        uint256 gaugeWeight = GuildToken(_guildToken).getGaugeWeight(
            address(this)
        );
        uint256 gaugeType = GuildToken(_guildToken).gaugeType(address(this));
        uint256 totalWeight = GuildToken(_guildToken).totalTypeWeight(
            gaugeType
        );
        if (gaugeWeightDelta < 0 && uint256(-gaugeWeightDelta) > gaugeWeight) {
            uint256 decrement = uint256(-gaugeWeightDelta);
            if (decrement > gaugeWeight || decrement > totalWeight) {
                // early return for cases where the hypothetical gaugeWeightDelta
                // would make the gaugeWeight or totalWeight <= 0.
                // This allows unchecked casting on the following lines.
                return 0;
            }
        }
        gaugeWeight = uint256(int256(gaugeWeight) + gaugeWeightDelta);
        totalWeight = uint256(int256(totalWeight) + gaugeWeightDelta);
        if (gaugeWeight == 0 || totalWeight == 0) {
            return 0; // no gauge vote or all gauges deprecated, 0 debt ceiling
        } else if (gaugeWeight == totalWeight) {
            // one gauge, unlimited debt ceiling
            return type(uint256).max;
        }
        uint256 _issuance = issuance; // cached SLOAD
        uint256 totalIssuance = ProfitManager(refs.profitManager)
            .totalIssuance();
        uint256 gaugeWeightTolerance = ProfitManager(refs.profitManager)
            .gaugeWeightTolerance();
        if (totalIssuance == 0 && gaugeWeight != 0) {
            // first-ever CREDIT mint on a non-zero gauge weight term
            // does not check the relative debt ceilings
            return type(uint256).max;
        }
        uint256 toleratedGaugeWeight = (gaugeWeight * gaugeWeightTolerance) /
            1e18;
        uint256 debtCeilingBefore = (totalIssuance * toleratedGaugeWeight) /
            totalWeight;
        // if already above cap, no more borrows allowed
        if (_issuance >= debtCeilingBefore) {
            return debtCeilingBefore;
        }
        /// @dev this can only underflow if gaugeWeightTolerance is < 1e18
        /// and that value is enforced >= 1e18 in the ProfitManager setter.
        uint256 remainingDebtCeiling = debtCeilingBefore - _issuance;
        if (toleratedGaugeWeight >= totalWeight) {
            // if the gauge weight is above 100% when we include tolerance,
            // the gauge relative debt ceilings are not constraining.
            return type(uint256).max;
        }
        /// @dev this can never underflow due to previous if() block
        uint256 otherGaugesWeight = totalWeight - toleratedGaugeWeight;

        uint256 maxBorrow = (remainingDebtCeiling * totalWeight) /
            otherGaugesWeight;
        return _issuance + maxBorrow;
    }

    /// @notice returns the debt ceiling without change to gauge weight
    function debtCeiling() public view returns (uint256) {
        return debtCeiling(0);
    }

    /// @notice initiate a new loan
    /// @param payer address depositing the collateral
    /// @param borrower address getting the borrowed funds
    /// @param borrowAmount amount of gUSDC borrowed
    /// @param collateralAmount the collateral amount deposited
    function _borrow(
        address payer,
        address borrower,
        uint256 borrowAmount,
        uint256 collateralAmount
    ) internal returns (bytes32 loanId) {
        require(borrowAmount != 0, "LendingTerm: cannot borrow 0");
        require(collateralAmount != 0, "LendingTerm: cannot stake 0");

        loanId = keccak256(
            abi.encode(borrower, address(this), block.timestamp)
        );

        // check that the loan doesn't already exist
        require(loans[loanId].borrowTime == 0, "LendingTerm: loan exists");

        // check that enough collateral is provided
        uint256 creditMultiplier = ProfitManager(refs.profitManager)
            .creditMultiplier();
        uint256 maxBorrow = _maxDebtForCollateral(
            collateralAmount,
            creditMultiplier
        );
        require(
            borrowAmount <= maxBorrow,
            "LendingTerm: not enough collateral"
        );

        // check that enough CREDIT is borrowed
        require(
            borrowAmount >= ProfitManager(refs.profitManager).minBorrow(),
            "LendingTerm: borrow amount too low"
        );

        // check the hardcap
        uint256 _issuance = issuance;
        uint256 _postBorrowIssuance = _issuance + borrowAmount;
        require(
            _postBorrowIssuance <= params.hardCap,
            "LendingTerm: hardcap reached"
        );

        // check the debt ceiling
        uint256 _debtCeiling = debtCeiling();
        require(
            _postBorrowIssuance <= _debtCeiling,
            "LendingTerm: debt ceiling reached"
        );

        // save loan in state
        loans[loanId] = Loan({
            borrower: borrower,
            borrowTime: uint48(block.timestamp),
            lastPartialRepay: uint48(block.timestamp),
            borrowAmount: borrowAmount,
            borrowCreditMultiplier: creditMultiplier,
            collateralAmount: collateralAmount,
            caller: address(0),
            callTime: 0,
            closeTime: 0,
            callDebt: 0
        });
        issuance = _postBorrowIssuance;

        // notify ProfitManager of issuance change
        ProfitManager(refs.profitManager).notifyPnL(
            address(this),
            0,
            int256(borrowAmount)
        );

        // mint debt to the borrower
        RateLimitedMinter(refs.creditMinter).mint(borrower, borrowAmount);

        // pull the collateral from the borrower
        IERC20(params.collateralToken).safeTransferFrom(
            payer,
            address(this),
            collateralAmount
        );

        // emit event
        emit LoanOpen(
            block.timestamp,
            loanId,
            borrower,
            collateralAmount,
            borrowAmount
        );
    }

    /// @notice initiate a new loan
    function borrow(
        uint256 borrowAmount,
        uint256 collateralAmount
    ) external whenNotPaused returns (bytes32 loanId) {
        loanId = _borrow(
            msg.sender,
            msg.sender,
            borrowAmount,
            collateralAmount
        );
    }

    /// @notice initiate a new loan on behalf of someone else
    function borrowOnBehalf(
        uint256 borrowAmount,
        uint256 collateralAmount,
        address onBehalfOf
    ) external whenNotPaused returns (bytes32 loanId) {
        loanId = _borrow(
            msg.sender,
            onBehalfOf,
            borrowAmount,
            collateralAmount
        );
    }

    /// @notice add collateral on an open loan.
    /// a borrower might want to add collateral so that his position does not go underwater due to
    /// interests growing up over time.
    function _addCollateral(
        address borrower,
        bytes32 loanId,
        uint256 collateralToAdd
    ) internal {
        require(collateralToAdd != 0, "LendingTerm: cannot add 0");

        Loan storage loan = loans[loanId];

        // check the loan is open
        require(loan.borrowTime != 0, "LendingTerm: loan not found");
        require(loan.closeTime == 0, "LendingTerm: loan closed");
        require(loan.callTime == 0, "LendingTerm: loan called");

        // update loan in state
        loans[loanId].collateralAmount += collateralToAdd;

        // pull the collateral from the borrower
        IERC20(params.collateralToken).safeTransferFrom(
            borrower,
            address(this),
            collateralToAdd
        );

        // emit event
        emit LoanAddCollateral(
            block.timestamp,
            loanId,
            borrower,
            collateralToAdd
        );
    }

    /// @notice add collateral on an open loan.
    function addCollateral(bytes32 loanId, uint256 collateralToAdd) external {
        _addCollateral(msg.sender, loanId, collateralToAdd);
    }

    /// @notice partially repay an open loan.
    /// a borrower might want to partially repay debt so that his position does not go underwater
    /// due to interests building up.
    /// some lending terms might also impose periodic partial repayments.
    function _partialRepay(
        address repayer,
        bytes32 loanId,
        uint256 debtToRepay
    ) internal {
        Loan storage loan = loans[loanId];

        // check the loan is open
        uint256 borrowTime = loan.borrowTime;
        require(borrowTime != 0, "LendingTerm: loan not found");
        require(
            borrowTime < block.timestamp,
            "LendingTerm: loan opened in same block"
        );
        require(loan.closeTime == 0, "LendingTerm: loan closed");
        require(loan.callTime == 0, "LendingTerm: loan called");

        // compute partial repayment
        uint256 creditMultiplier = ProfitManager(refs.profitManager)
            .creditMultiplier();
        uint256 loanDebt = _getLoanDebt(loanId, creditMultiplier);
        require(debtToRepay < loanDebt, "LendingTerm: full repayment");
        uint256 borrowAmount = loan.borrowAmount;
        uint256 principalRepaid = (borrowAmount *
            loan.borrowCreditMultiplier *
            debtToRepay) /
            creditMultiplier /
            loanDebt;
        uint256 interestRepaid = debtToRepay - principalRepaid;
        uint256 issuanceDecrease = (borrowAmount * debtToRepay) / loanDebt;

        require(principalRepaid != 0, "LendingTerm: repay too small");
        require(
            debtToRepay >= (loanDebt * params.minPartialRepayPercent) / 1e18,
            "LendingTerm: repay below min"
        );
        require(
            borrowAmount - issuanceDecrease >
                ProfitManager(refs.profitManager).minBorrow(),
            "LendingTerm: below min borrow"
        );

        // update loan in state
        loans[loanId].borrowAmount -= issuanceDecrease;
        loans[loanId].lastPartialRepay = uint48(block.timestamp);
        issuance -= issuanceDecrease;

        // pull the debt from the borrower
        CreditToken(refs.creditToken).transferFrom(
            repayer,
            address(this),
            debtToRepay
        );

        // forward profit portion to the ProfitManager, burn the rest
        if (interestRepaid != 0) {
            CreditToken(refs.creditToken).transfer(
                refs.profitManager,
                interestRepaid
            );
            ProfitManager(refs.profitManager).notifyPnL(
                address(this),
                int256(interestRepaid),
                -int256(issuanceDecrease)
            );
        }
        CreditToken(refs.creditToken).burn(principalRepaid);
        RateLimitedMinter(refs.creditMinter).replenishBuffer(principalRepaid);

        // emit event
        emit LoanPartialRepay(block.timestamp, loanId, repayer, debtToRepay);
    }

    /// @notice partially repay an open loan.
    function partialRepay(bytes32 loanId, uint256 debtToRepay) external {
        _partialRepay(msg.sender, loanId, debtToRepay);
    }

    /// @notice repay an open loan
    function _repay(address repayer, bytes32 loanId) internal {
        Loan storage loan = loans[loanId];

        // check the loan is open
        uint256 borrowTime = loan.borrowTime;
        require(borrowTime != 0, "LendingTerm: loan not found");
        require(
            borrowTime < block.timestamp,
            "LendingTerm: loan opened in same block"
        );
        require(loan.closeTime == 0, "LendingTerm: loan closed");
        require(loan.callTime == 0, "LendingTerm: loan called");

        // compute interest owed
        uint256 creditMultiplier = ProfitManager(refs.profitManager)
            .creditMultiplier();
        uint256 loanDebt = _getLoanDebt(loanId, creditMultiplier);
        uint256 borrowAmount = loan.borrowAmount;
        uint256 principal = (borrowAmount * loan.borrowCreditMultiplier) /
            creditMultiplier;
        uint256 interest = loanDebt - principal;

        /// pull debt from the borrower and replenish the buffer of available debt that can be minted.
        CreditToken(refs.creditToken).transferFrom(
            repayer,
            address(this),
            loanDebt
        );
        if (interest != 0) {
            // forward profit portion to the ProfitManager
            CreditToken(refs.creditToken).transfer(
                refs.profitManager,
                interest
            );

            // report profit
            ProfitManager(refs.profitManager).notifyPnL(
                address(this),
                int256(interest),
                -int256(borrowAmount)
            );
        }

        // burn loan principal
        CreditToken(refs.creditToken).burn(principal);
        RateLimitedMinter(refs.creditMinter).replenishBuffer(principal);

        // close the loan
        loan.closeTime = uint48(block.timestamp);
        issuance -= borrowAmount;

        // return the collateral to the borrower
        IERC20(params.collateralToken).safeTransfer(
            loan.borrower,
            loan.collateralAmount
        );

        // emit event
        emit LoanClose(block.timestamp, loanId, LoanCloseType.Repay, loanDebt);
    }

    /// @notice repay an open loan
    function repay(bytes32 loanId) external {
        _repay(msg.sender, loanId);
    }

    /// @notice call a loan, the collateral will be auctioned to repay outstanding debt.
    /// Loans can be called only if the term has been offboarded or if a loan missed a periodic partialRepay.
    function _call(
        address caller,
        bytes32 loanId,
        address _auctionHouse
    ) internal {
        Loan storage loan = loans[loanId];

        // check that the loan exists
        uint256 borrowTime = loan.borrowTime;
        require(loan.borrowTime != 0, "LendingTerm: loan not found");

        // check that the loan is not already closed
        require(loan.closeTime == 0, "LendingTerm: loan closed");

        // check that the loan is not already called
        require(loan.callTime == 0, "LendingTerm: loan called");

        // check that the loan can be called
        uint256 creditMultiplier = ProfitManager(refs.profitManager)
            .creditMultiplier();
        uint256 loanDebt = _getLoanDebt(loanId, creditMultiplier);
        require(
            GuildToken(refs.guildToken).isDeprecatedGauge(address(this)) ||
                loanDebt >
                _maxDebtForCollateral(
                    loans[loanId].collateralAmount,
                    creditMultiplier
                ) ||
                partialRepayDelayPassed(loanId),
            "LendingTerm: cannot call"
        );

        // check that the loan has been running for at least 1 block
        require(
            borrowTime < block.timestamp,
            "LendingTerm: loan opened in same block"
        );

        // update loan in state
        loans[loanId].callTime = uint48(block.timestamp);
        loans[loanId].callDebt = loanDebt;
        loans[loanId].caller = caller;

        // auction the loan collateral
        AuctionHouse(_auctionHouse).startAuction(loanId);

        // emit event
        emit LoanCall(block.timestamp, loanId);
    }

    /// @notice call a single loan
    function call(bytes32 loanId) external {
        _call(msg.sender, loanId, refs.auctionHouse);
    }

    /// @notice call a list of loans
    function callMany(bytes32[] memory loanIds) public {
        address _auctionHouse = refs.auctionHouse;
        for (uint256 i = 0; i < loanIds.length; i++) {
            _call(msg.sender, loanIds[i], _auctionHouse);
        }
    }

    /// @notice forgive a loan, marking its debt as a total loss to the system.
    /// The loan is closed (borrower keeps the CREDIT), and the collateral stays on the LendingTerm.
    /// Governance can later unstuck the collateral through `emergencyAction`.
    /// This function is made for emergencies where collateral is frozen or other reverting
    /// conditions on collateral transfers that prevent regular repay() or call() loan closing.
    function forgive(bytes32 loanId) external onlyCoreRole(CoreRoles.GOVERNOR) {
        Loan storage loan = loans[loanId];

        // check that the loan exists
        require(loan.borrowTime != 0, "LendingTerm: loan not found");

        // check that the loan is not already called
        require(loan.callTime == 0, "LendingTerm: loan called");

        // check that the loan is not already closed
        require(loan.closeTime == 0, "LendingTerm: loan closed");

        // close the loan
        loans[loanId].closeTime = uint48(block.timestamp);
        uint256 borrowAmount = loans[loanId].borrowAmount;
        issuance -= borrowAmount;

        // mark loan as a total loss
        uint256 creditMultiplier = ProfitManager(refs.profitManager)
            .creditMultiplier();
        uint256 principal = (borrowAmount *
            loans[loanId].borrowCreditMultiplier) / creditMultiplier;
        int256 pnl = -int256(principal);
        ProfitManager(refs.profitManager).notifyPnL(
            address(this),
            pnl,
            -int256(borrowAmount)
        );

        // emit event
        emit LoanClose(block.timestamp, loanId, LoanCloseType.Forgive, 0);
    }

    /// @notice callback from the auctionHouse when au auction concludes
    function onBid(
        bytes32 loanId,
        address bidder,
        uint256 collateralToBorrower,
        uint256 collateralToBidder,
        uint256 creditFromBidder
    ) external {
        // preliminary checks
        require(msg.sender == refs.auctionHouse, "LendingTerm: invalid caller");
        require(
            loans[loanId].callTime != 0 && loans[loanId].callDebt != 0,
            "LendingTerm: loan not called"
        );
        require(loans[loanId].closeTime == 0, "LendingTerm: loan closed");

        // sanity check on collateral movement
        // these should never fail for a properly implemented AuctionHouse contract
        // collateralOut == 0 if forgive() while in auctionHouse
        uint256 collateralOut = collateralToBorrower + collateralToBidder;
        require(
            collateralOut == loans[loanId].collateralAmount ||
                collateralOut == 0,
            "LendingTerm: invalid collateral movements"
        );

        // compute pnl
        uint256 creditMultiplier = ProfitManager(refs.profitManager)
            .creditMultiplier();
        uint256 borrowAmount = loans[loanId].borrowAmount;
        uint256 principal = (borrowAmount *
            loans[loanId].borrowCreditMultiplier) / creditMultiplier;
        int256 pnl;
        uint256 interest;
        if (creditFromBidder >= principal) {
            interest = creditFromBidder - principal;
            pnl = int256(interest);
        } else {
            pnl = int256(creditFromBidder) - int256(principal);
            principal = creditFromBidder;
            require(
                collateralToBorrower == 0,
                "LendingTerm: invalid collateral movement"
            );
        }

        // save loan state
        loans[loanId].closeTime = uint48(block.timestamp);

        // pull credit from bidder
        if (creditFromBidder != 0) {
            CreditToken(refs.creditToken).transferFrom(
                bidder,
                address(this),
                creditFromBidder
            );
        }

        // burn credit principal, replenish buffer
        if (principal != 0) {
            CreditToken(refs.creditToken).burn(principal);
            RateLimitedMinter(refs.creditMinter).replenishBuffer(principal);
        }

        // handle profit & losses
        if (pnl != 0) {
            // forward profit, if any
            if (interest != 0) {
                CreditToken(refs.creditToken).transfer(
                    refs.profitManager,
                    interest
                );
            }
            ProfitManager(refs.profitManager).notifyPnL(
                address(this),
                pnl,
                -int256(borrowAmount)
            );
        }

        // decrease issuance
        issuance -= borrowAmount;

        // send collateral to borrower
        if (collateralToBorrower != 0) {
            IERC20(params.collateralToken).safeTransfer(
                loans[loanId].borrower,
                collateralToBorrower
            );
        }

        // send collateral to bidder
        if (collateralToBidder != 0) {
            IERC20(params.collateralToken).safeTransfer(
                bidder,
                collateralToBidder
            );
        }

        emit LoanClose(
            block.timestamp,
            loanId,
            LoanCloseType.Call,
            creditFromBidder
        );
    }

    /// @notice set the address of the auction house.
    /// governor-only, to allow full governance to update the auction mechanisms.
    function setAuctionHouse(
        address _newValue
    ) external onlyCoreRole(CoreRoles.GOVERNOR) {
        // allow configuration changes only when there are no auctions in progress.
        // updating the auction house while auctions are in progress could break the loan
        // lifecycle, as it would prevent the former auctionHouse (that have active auctions)
        // from reporting the result to the lending term.
        require(
            AuctionHouse(refs.auctionHouse).nAuctionsInProgress() == 0,
            "LendingTerm: auctions in progress"
        );

        refs.auctionHouse = _newValue;
        emit SetAuctionHouse(block.timestamp, _newValue);
    }

    /// @notice set the hardcap of CREDIT mintable in this term.
    /// allows to update a term's arbitrary hardcap without doing a gauge & loans migration.
    function setHardCap(
        uint256 _newValue
    ) external onlyCoreRole(CoreRoles.GOVERNOR) {
        params.hardCap = _newValue;
        emit SetHardCap(block.timestamp, _newValue);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import {CoreRef} from "@src/core/CoreRef.sol";
import {CoreRoles} from "@src/core/CoreRoles.sol";
import {ERC20MultiVotes} from "@src/tokens/ERC20MultiVotes.sol";
import {ERC20RebaseDistributor} from "@src/tokens/ERC20RebaseDistributor.sol";

/** 
@title  CREDIT ERC20 Token
@author eswak
@notice This is the debt token of the Ethereum Credit Guild.
*/
contract CreditToken is
    CoreRef,
    ERC20Burnable,
    ERC20MultiVotes,
    ERC20RebaseDistributor
{
    constructor(
        address _core,
        string memory _name,
        string memory _symbol
    ) CoreRef(_core) ERC20(_name, _symbol) ERC20Permit(_name) {}

    /// @notice Mint new tokens to the target address
    function mint(
        address to,
        uint256 amount
    ) external onlyCoreRole(CoreRoles.CREDIT_MINTER) {
        _mint(to, amount);
    }

    /// @notice Destroys `amount` tokens from the caller.
    function burn(
        uint256 amount
    ) public override onlyCoreRole(CoreRoles.CREDIT_BURNER) {
        super.burn(amount);
    }

    /// @notice Destroys `amount` tokens from `account`, deducting from the caller's allowance.
    function burnFrom(
        address account,
        uint256 amount
    ) public override onlyCoreRole(CoreRoles.CREDIT_BURNER) {
        super.burnFrom(account, amount);
    }

    /// @notice Set `maxDelegates`, the maximum number of addresses any account can delegate voting power to.
    function setMaxDelegates(
        uint256 newMax
    ) external onlyCoreRole(CoreRoles.CREDIT_GOVERNANCE_PARAMETERS) {
        _setMaxDelegates(newMax);
    }

    /// @notice Allow or disallow an address to delegate voting power to more addresses than `maxDelegates`.
    function setContractExceedMaxDelegates(
        address account,
        bool canExceedMax
    ) external onlyCoreRole(CoreRoles.CREDIT_GOVERNANCE_PARAMETERS) {
        _setContractExceedMaxDelegates(account, canExceedMax);
    }

    /// @notice Set the lockup period after delegating votes
    function setDelegateLockupPeriod(
        uint256 newValue
    ) external onlyCoreRole(CoreRoles.CREDIT_GOVERNANCE_PARAMETERS) {
        _setDelegateLockupPeriod(newValue);
    }

    /// @notice Force an address to enter rebase.
    function forceEnterRebase(
        address account
    ) external onlyCoreRole(CoreRoles.CREDIT_REBASE_PARAMETERS) {
        require(
            rebasingState[account].isRebasing == 0,
            "CreditToken: already rebasing"
        );
        _enterRebase(account);
    }

    /// @notice Force an address to exit rebase.
    function forceExitRebase(
        address account
    ) external onlyCoreRole(CoreRoles.CREDIT_REBASE_PARAMETERS) {
        require(
            rebasingState[account].isRebasing == 1,
            "CreditToken: not rebasing"
        );
        _exitRebase(account);
    }

    /*///////////////////////////////////////////////////////////////
                        Inheritance reconciliation
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20RebaseDistributor) {
        ERC20RebaseDistributor._mint(account, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20MultiVotes, ERC20RebaseDistributor) {
        _decrementVotesUntilFree(account, amount); // from ERC20MultiVotes
        _checkDelegateLockupPeriod(account); // from ERC20MultiVotes
        ERC20RebaseDistributor._burn(account, amount);
    }

    function balanceOf(
        address account
    ) public view override(ERC20, ERC20RebaseDistributor) returns (uint256) {
        return ERC20RebaseDistributor.balanceOf(account);
    }

    function totalSupply()
        public
        view
        override(ERC20, ERC20RebaseDistributor)
        returns (uint256)
    {
        return ERC20RebaseDistributor.totalSupply();
    }

    function transfer(
        address to,
        uint256 amount
    )
        public
        override(ERC20, ERC20MultiVotes, ERC20RebaseDistributor)
        returns (bool)
    {
        _decrementVotesUntilFree(msg.sender, amount); // from ERC20MultiVotes
        _checkDelegateLockupPeriod(msg.sender); // from ERC20MultiVotes
        return ERC20RebaseDistributor.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        public
        override(ERC20, ERC20MultiVotes, ERC20RebaseDistributor)
        returns (bool)
    {
        _decrementVotesUntilFree(from, amount); // from ERC20MultiVotes
        _checkDelegateLockupPeriod(from); // from ERC20MultiVotes
        return ERC20RebaseDistributor.transferFrom(from, to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {CoreRef} from "@src/core/CoreRef.sol";
import {CoreRoles} from "@src/core/CoreRoles.sol";
import {GuildToken} from "@src/tokens/GuildToken.sol";
import {CreditToken} from "@src/tokens/CreditToken.sol";

/** 
@title ProfitManager
@author eswak
@notice This contract manages profits generated in the system and how it is distributed
    between the various stakeholders.

    This contract also manages a surplus buffer, which acts as first-loss capital in case of
    bad debt. When bad debt is created beyond the surplus buffer, this contract decrements
    the `creditMultiplier` value held in its storage, which has the effect of reducing the
    value of CREDIT everywhere in the system.

    When a loan generates profit (interests), the profit is traced back to users voting for
    this lending term (gauge), which subsequently allows pro-rata distribution of profits to
    GUILD holders that vote for the most productive gauges.

    Seniority stack of the debt, in case of losses :
    - per term surplus buffer (donated to global surplus buffer when loss is reported)
    - global surplus buffer
    - finally, credit holders (by updating down the creditMultiplier)
*/
contract ProfitManager is CoreRef {
    /// @notice reference to GUILD token.
    address public guild;

    /// @notice reference to CREDIT token.
    address public credit;

    /// @notice profit index of a given gauge
    mapping(address => uint256) public gaugeProfitIndex;

    /// @notice profit index of a given user in a given gauge
    mapping(address => mapping(address => uint256)) public userGaugeProfitIndex;

    /// @dev internal structure used to optimize storage read, public functions use
    /// uint256 numbers with 18 decimals.
    struct ProfitSharingConfig {
        uint32 surplusBufferSplit; // percentage, with 9 decimals (!) that go to surplus buffer
        uint32 guildSplit; // percentage, with 9 decimals (!) that go to GUILD holders
        uint32 otherSplit; // percentage, with 9 decimals (!) that go to other address if != address(0)
        address otherRecipient; // address receiving `otherSplit`
    }

    /// @notice configuration of profit sharing.
    /// `surplusBufferSplit`, `guildSplit`, and `otherSplit` are expressed as percentages with 9 decimals,
    /// so a value of 1e9 would direct 100% of profits. The sum should be <= 1e9.
    /// The rest (if the sum of `guildSplit` + `otherSplit` is < 1e9) is distributed to lenders of the
    /// system, CREDIT holders, through the rebasing mechanism (`CreditToken.distribute()`).
    /// If `otherRecipient` is set to address(0), `otherSplit` must equal 0.
    /// The share of profit to `otherRecipient` is sent through a regular ERC20.transfer().
    /// This structure is optimized for storage packing, all external interfaces reference
    /// percentages encoded as uint256 with 18 decimals.
    ProfitSharingConfig internal profitSharingConfig;

    /// @notice amount of first-loss capital in the system.
    /// This is a number of CREDIT token held on this contract that can be used to absorb losses in
    /// cases where a loss is reported through `notifyPnL`. The surplus buffer is depleted first, and
    /// if the loss is greater than the surplus buffer, the `creditMultiplier` is updated down.
    uint256 public surplusBuffer;

    /// @notice amount of first-loss capital for a given term.
    /// This is a number of CREDIT token held on this contract that can be used to absorb losses in
    /// cases where a loss is reported through `notifyPnL` in a given term.
    /// When a loss is reported in a given term, its termSuplusBuffer is donated to the general
    /// surplusBuffer before calculating the loss.
    mapping(address => uint256) public termSurplusBuffer;

    /// @notice multiplier for CREDIT value in the system.
    /// e.g. a value of 0.7e18 would mean that CREDIT has been discounted by 30% so far in the system,
    /// and that all lending terms will allow 1/0.7=1.42 times more CREDIT to be borrowed per collateral
    /// tokens, and all active debts are also affected by this multiplier during the update (e.g. if an
    /// address owed 1000 CREDIT in an active loan, they now owe 1428 CREDIT).
    /// The CREDIT multiplier can only go down (CREDIT can only lose value over time, when bad debt
    /// is created in the system). To make CREDIT a valuable asset to hold, profits generated by the system
    /// shall be redistributed to holders through a savings rate or another mechanism.
    uint256 public creditMultiplier = 1e18;

    /// @notice minimum size of CREDIT loans.
    /// this parameter is here to ensure that the gas costs of liquidation do not
    /// outsize minimum overcollateralization (which could result in bad debt
    /// on otherwise sound loans).
    /// This value is adjusted up when the creditMultiplier goes down.
    uint256 internal _minBorrow = 100e18;

    /// @notice tolerance on new borrows regarding gauge weights.
    /// For a total supply or 100 credit, and 2 gauges each at 50% weight,
    /// the ideal borrow amount for each gauge is 50 credit. To facilitate
    /// growth of the protocol, a tolerance is allowed compared to the ideal
    /// gauge weights.
    /// This tolerance is expressed as a percentage with 18 decimals.
    /// A tolerance of 1e18 (100% - or 0% deviation compared to ideal weights)
    /// can result in a deadlock situation where no new borrows are allowed.
    uint256 public gaugeWeightTolerance = 1.2e18; // 120%

    /// @notice total amount of CREDIT issued in the lending terms of this market.
    /// Should be equal to the sum of all LendingTerm.issuance().
    uint256 public totalIssuance;

    /// @notice maximum total amount of CREDIT allowed to be issued in this market.
    /// This value is adjusted up when the creditMultiplier goes down.
    /// This is set to a very large value by default to not restrict usage by default.
    uint256 public _maxTotalIssuance = 1e30;

    constructor(address _core) CoreRef(_core) {
        emit MinBorrowUpdate(block.timestamp, 100e18);
    }

    /// @notice emitted when a profit or loss in a gauge is notified.
    event GaugePnL(address indexed gauge, uint256 indexed when, int256 pnl);

    /// @notice emitted when surplus buffer is updated.
    event SurplusBufferUpdate(uint256 indexed when, uint256 newValue);

    /// @notice emitted when surplus buffer of a given term is updated.
    event TermSurplusBufferUpdate(
        uint256 indexed when,
        address indexed term,
        uint256 newValue
    );

    /// @notice emitted when CREDIT multiplier is updated.
    event CreditMultiplierUpdate(uint256 indexed when, uint256 newValue);

    /// @notice emitted when GUILD profit sharing is updated.
    event ProfitSharingConfigUpdate(
        uint256 indexed when,
        uint256 surplusBufferSplit,
        uint256 creditSplit,
        uint256 guildSplit,
        uint256 otherSplit,
        address otherRecipient
    );

    /// @notice emitted when a GUILD member claims their CREDIT rewards.
    event ClaimRewards(
        uint256 indexed when,
        address indexed user,
        address indexed gauge,
        uint256 amount
    );

    /// @notice emitted when minBorrow is updated
    event MinBorrowUpdate(uint256 indexed when, uint256 newValue);

    /// @notice emitted when maxTotalIssuance is updated
    event MaxTotalIssuanceUpdate(uint256 indexed when, uint256 newValue);

    /// @notice emitted when gaugeWeightTolerance is updated
    event GaugeWeightToleranceUpdate(uint256 indexed when, uint256 newValue);

    /// @notice get the minimum borrow amount
    function minBorrow() external view returns (uint256) {
        return (_minBorrow * 1e18) / creditMultiplier;
    }

    /// @notice get the maximum total issuance
    function maxTotalIssuance() external view returns (uint256) {
        return (_maxTotalIssuance * 1e18) / creditMultiplier;
    }

    /// @notice initialize references to GUILD & CREDIT tokens.
    function initializeReferences(
        address _credit,
        address _guild
    ) external onlyCoreRole(CoreRoles.GOVERNOR) {
        assert(credit == address(0) && guild == address(0));
        credit = _credit;
        guild = _guild;
    }

    /// @notice set the minimum borrow amount
    function setMinBorrow(
        uint256 newValue
    ) external onlyCoreRole(CoreRoles.GOVERNOR) {
        _minBorrow = newValue;
        emit MinBorrowUpdate(block.timestamp, newValue);
    }

    /// @notice set the maximum total issuance
    function setMaxTotalIssuance(
        uint256 newValue
    ) external onlyCoreRole(CoreRoles.GOVERNOR) {
        _maxTotalIssuance = newValue;
        emit MaxTotalIssuanceUpdate(block.timestamp, newValue);
    }

    /// @notice set the gauge weight tolerance
    function setGaugeWeightTolerance(
        uint256 newValue
    ) external onlyCoreRole(CoreRoles.GOVERNOR) {
        require(newValue >= 1e18, "ProfitManager: invalid tolerance");
        gaugeWeightTolerance = newValue;
        emit GaugeWeightToleranceUpdate(block.timestamp, newValue);
    }

    /// @notice set the profit sharing config.
    function setProfitSharingConfig(
        uint256 surplusBufferSplit,
        uint256 creditSplit,
        uint256 guildSplit,
        uint256 otherSplit,
        address otherRecipient
    ) external onlyCoreRole(CoreRoles.GOVERNOR) {
        if (otherRecipient == address(0)) {
            require(otherSplit == 0, "GuildToken: invalid config");
        } else {
            require(otherSplit != 0, "GuildToken: invalid config");
        }
        require(
            surplusBufferSplit + otherSplit + guildSplit + creditSplit == 1e18,
            "GuildToken: invalid config"
        );

        profitSharingConfig = ProfitSharingConfig({
            surplusBufferSplit: uint32(surplusBufferSplit / 1e9),
            guildSplit: uint32(guildSplit / 1e9),
            otherSplit: uint32(otherSplit / 1e9),
            otherRecipient: otherRecipient
        });

        emit ProfitSharingConfigUpdate(
            block.timestamp,
            surplusBufferSplit,
            creditSplit,
            guildSplit,
            otherSplit,
            otherRecipient
        );
    }

    /// @notice get the profit sharing config.
    function getProfitSharingConfig()
        external
        view
        returns (
            uint256 surplusBufferSplit,
            uint256 creditSplit,
            uint256 guildSplit,
            uint256 otherSplit,
            address otherRecipient
        )
    {
        surplusBufferSplit =
            uint256(profitSharingConfig.surplusBufferSplit) *
            1e9;
        guildSplit = uint256(profitSharingConfig.guildSplit) * 1e9;
        otherSplit = uint256(profitSharingConfig.otherSplit) * 1e9;
        creditSplit = 1e18 - surplusBufferSplit - guildSplit - otherSplit;
        otherRecipient = profitSharingConfig.otherRecipient;
    }

    /// @notice donate to surplus buffer
    function donateToSurplusBuffer(uint256 amount) external {
        uint256 newSurplusBuffer = surplusBuffer + amount;
        surplusBuffer = newSurplusBuffer;
        CreditToken(credit).transferFrom(msg.sender, address(this), amount);
        emit SurplusBufferUpdate(block.timestamp, newSurplusBuffer);
    }

    /// @notice donate to surplus buffer of a given term
    function donateToTermSurplusBuffer(address term, uint256 amount) external {
        CreditToken(credit).transferFrom(msg.sender, address(this), amount);
        uint256 newSurplusBuffer = termSurplusBuffer[term] + amount;
        termSurplusBuffer[term] = newSurplusBuffer;
        emit TermSurplusBufferUpdate(block.timestamp, term, newSurplusBuffer);
    }

    /// @notice withdraw from surplus buffer
    function withdrawFromSurplusBuffer(
        address to,
        uint256 amount
    ) external onlyCoreRole(CoreRoles.GUILD_SURPLUS_BUFFER_WITHDRAW) {
        uint256 newSurplusBuffer = surplusBuffer - amount; // this would revert due to underflow if withdrawing > surplusBuffer
        surplusBuffer = newSurplusBuffer;
        CreditToken(credit).transfer(to, amount);
        emit SurplusBufferUpdate(block.timestamp, newSurplusBuffer);
    }

    /// @notice withdraw from surplus buffer of a given term
    function withdrawFromTermSurplusBuffer(
        address term,
        address to,
        uint256 amount
    ) external onlyCoreRole(CoreRoles.GUILD_SURPLUS_BUFFER_WITHDRAW) {
        uint256 newSurplusBuffer = termSurplusBuffer[term] - amount; // this would revert due to underflow if withdrawing > termSurplusBuffer
        termSurplusBuffer[term] = newSurplusBuffer;
        CreditToken(credit).transfer(to, amount);
        emit TermSurplusBufferUpdate(block.timestamp, term, newSurplusBuffer);
    }

    /// @notice notify profit and loss in a given gauge
    /// if `amount` is > 0, the same number of CREDIT tokens are expected to be transferred to this contract
    /// before `notifyPnL` is called.
    function notifyPnL(
        address gauge,
        int256 amount,
        int256 issuanceDelta
    ) external onlyCoreRole(CoreRoles.GAUGE_PNL_NOTIFIER) {
        uint256 _surplusBuffer = surplusBuffer;
        uint256 _termSurplusBuffer = termSurplusBuffer[gauge];
        address _credit = credit;

        // underflow should not be possible because the issuance() in the
        // lending terms are all unsigned integers and they all notify on
        // increment/decrement.
        totalIssuance = uint256(int256(totalIssuance) + issuanceDelta);

        // check the maximum total issuance if the issuance is changing
        if (issuanceDelta > 0) {
            uint256 __maxTotalIssuance = (_maxTotalIssuance * 1e18) /
                creditMultiplier;
            require(
                totalIssuance <= __maxTotalIssuance,
                "ProfitManager: global debt ceiling reached"
            );
        }

        // handling loss
        if (amount < 0) {
            uint256 loss = uint256(-amount);

            // save gauge loss
            GuildToken(guild).notifyGaugeLoss(gauge);

            // deplete the term surplus buffer, if any, and
            // donate its content to the general surplus buffer
            if (_termSurplusBuffer != 0) {
                termSurplusBuffer[gauge] = 0;
                emit TermSurplusBufferUpdate(block.timestamp, gauge, 0);
                _surplusBuffer += _termSurplusBuffer;
            }

            if (loss < _surplusBuffer) {
                // deplete the surplus buffer
                surplusBuffer = _surplusBuffer - loss;
                emit SurplusBufferUpdate(
                    block.timestamp,
                    _surplusBuffer - loss
                );
                CreditToken(_credit).burn(loss);
            } else {
                // empty the surplus buffer
                loss -= _surplusBuffer;
                surplusBuffer = 0;
                CreditToken(_credit).burn(_surplusBuffer);
                emit SurplusBufferUpdate(block.timestamp, 0);

                // update the CREDIT multiplier
                uint256 creditTotalSupply = CreditToken(_credit)
                    .targetTotalSupply();
                uint256 newCreditMultiplier = 0;
                if (loss < creditTotalSupply) {
                    // a loss greater than the total supply could occur due to outstanding loan
                    // debts being rounded up through the formula in lending terms :
                    // principal = borrowed * openCreditMultiplier / currentCreditMultiplier
                    // In this case, the creditMultiplier is set to 0.
                    newCreditMultiplier =
                        (creditMultiplier * (creditTotalSupply - loss)) /
                        creditTotalSupply;
                }
                creditMultiplier = newCreditMultiplier;
                emit CreditMultiplierUpdate(
                    block.timestamp,
                    newCreditMultiplier
                );
            }
        }
        // handling profit
        else if (amount > 0) {
            ProfitSharingConfig
                memory _profitSharingConfig = profitSharingConfig;

            uint256 amountForSurplusBuffer = (uint256(amount) *
                uint256(_profitSharingConfig.surplusBufferSplit)) / 1e9;

            uint256 amountForGuild = (uint256(amount) *
                uint256(_profitSharingConfig.guildSplit)) / 1e9;

            uint256 amountForOther = (uint256(amount) *
                uint256(_profitSharingConfig.otherSplit)) / 1e9;

            // distribute to surplus buffer
            if (amountForSurplusBuffer != 0) {
                surplusBuffer = _surplusBuffer + amountForSurplusBuffer;
                emit SurplusBufferUpdate(
                    block.timestamp,
                    _surplusBuffer + amountForSurplusBuffer
                );
            }

            // distribute to other
            if (amountForOther != 0) {
                CreditToken(_credit).transfer(
                    _profitSharingConfig.otherRecipient,
                    amountForOther
                );
            }

            // distribute to lenders
            {
                uint256 amountForCredit = uint256(amount) -
                    amountForSurplusBuffer -
                    amountForGuild -
                    amountForOther;
                if (amountForCredit != 0) {
                    CreditToken(_credit).distribute(amountForCredit);
                }
            }

            // distribute to the guild
            if (amountForGuild != 0) {
                // update the gauge profit index
                // if the gauge has 0 weight, does not update the profit index, this is unnecessary
                // because the profit index is used to reattribute profit to users voting for the gauge,
                // and if the weigth is 0, there are no users voting for the gauge.
                uint256 _gaugeWeight = uint256(
                    GuildToken(guild).getGaugeWeight(gauge)
                );
                if (_gaugeWeight != 0) {
                    uint256 _gaugeProfitIndex = gaugeProfitIndex[gauge];
                    if (_gaugeProfitIndex == 0) {
                        _gaugeProfitIndex = 1e18;
                    }
                    gaugeProfitIndex[gauge] =
                        _gaugeProfitIndex +
                        (amountForGuild * 1e18) /
                        _gaugeWeight;
                }
            }
        }

        emit GaugePnL(gauge, block.timestamp, amount);
    }

    /// @notice claim a user's rewards for a given gauge.
    /// @dev This should be called every time the user's weight changes in the gauge.
    function claimGaugeRewards(
        address user,
        address gauge
    ) public returns (uint256 creditEarned) {
        uint256 _userGaugeWeight = uint256(
            GuildToken(guild).getUserGaugeWeight(user, gauge)
        );
        uint256 _userGaugeProfitIndex = userGaugeProfitIndex[user][gauge];
        if (_userGaugeProfitIndex == 0) {
            _userGaugeProfitIndex = 1e18;
        }
        uint256 _gaugeProfitIndex = gaugeProfitIndex[gauge];
        if (_gaugeProfitIndex == 0) {
            _gaugeProfitIndex = 1e18;
        }
        userGaugeProfitIndex[user][gauge] = _gaugeProfitIndex;
        if (_userGaugeWeight == 0) {
            return 0;
        }
        uint256 deltaIndex = _gaugeProfitIndex - _userGaugeProfitIndex;
        if (deltaIndex != 0) {
            creditEarned = (_userGaugeWeight * deltaIndex) / 1e18;
            emit ClaimRewards(block.timestamp, user, gauge, creditEarned);
            CreditToken(credit).transfer(user, creditEarned);
        }
    }

    /// @notice claim a user's rewards across all their active gauges.
    function claimRewards(
        address user
    ) external returns (uint256 creditEarned) {
        address[] memory gauges = GuildToken(guild).userGauges(user);
        for (uint256 i = 0; i < gauges.length; ) {
            creditEarned += claimGaugeRewards(user, gauges[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice read & return pending undistributed rewards for a given user
    function getPendingRewards(
        address user
    )
        external
        view
        returns (
            address[] memory gauges,
            uint256[] memory creditEarned,
            uint256 totalCreditEarned
        )
    {
        address _guild = guild;
        gauges = GuildToken(_guild).userGauges(user);
        creditEarned = new uint256[](gauges.length);

        for (uint256 i = 0; i < gauges.length; ) {
            address gauge = gauges[i];
            uint256 _gaugeProfitIndex = gaugeProfitIndex[gauge];
            uint256 _userGaugeProfitIndex = userGaugeProfitIndex[user][gauge];

            if (_gaugeProfitIndex == 0) {
                _gaugeProfitIndex = 1e18;
            }

            // this should never fail, because when the user increment weight
            // a call to claimGaugeRewards() is made that initializes this value
            assert(_userGaugeProfitIndex != 0);

            uint256 deltaIndex = _gaugeProfitIndex - _userGaugeProfitIndex;
            if (deltaIndex != 0) {
                uint256 _userGaugeWeight = uint256(
                    GuildToken(_guild).getUserGaugeWeight(user, gauge)
                );
                creditEarned[i] = (_userGaugeWeight * deltaIndex) / 1e18;
                totalCreditEarned += creditEarned[i];
            }

            unchecked {
                ++i;
            }
        }
    }
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {CoreRoles} from "@src/core/CoreRoles.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/// @title Core access control of the Ethereum Credit Guild
/// @author eswak
/// @notice maintains roles and access control
contract Core is AccessControlEnumerable {
    /// @notice construct Core
    constructor() {
        // For initial setup before going live, deployer can then call
        // renounceRole(bytes32 role, address account)
        _grantRole(CoreRoles.GOVERNOR, msg.sender);

        // Initial roles setup: direct hierarchy, everything under governor
        _setRoleAdmin(CoreRoles.GOVERNOR, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.GUARDIAN, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.CREDIT_MINTER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.CREDIT_BURNER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.RATE_LIMITED_CREDIT_MINTER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.GUILD_MINTER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.RATE_LIMITED_GUILD_MINTER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.GAUGE_ADD, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.GAUGE_REMOVE, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.GAUGE_PARAMETERS, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.GAUGE_PNL_NOTIFIER, CoreRoles.GOVERNOR);
        _setRoleAdmin(
            CoreRoles.GUILD_GOVERNANCE_PARAMETERS,
            CoreRoles.GOVERNOR
        );
        _setRoleAdmin(
            CoreRoles.GUILD_SURPLUS_BUFFER_WITHDRAW,
            CoreRoles.GOVERNOR
        );
        _setRoleAdmin(
            CoreRoles.CREDIT_GOVERNANCE_PARAMETERS,
            CoreRoles.GOVERNOR
        );
        _setRoleAdmin(CoreRoles.CREDIT_REBASE_PARAMETERS, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.TIMELOCK_PROPOSER, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.TIMELOCK_EXECUTOR, CoreRoles.GOVERNOR);
        _setRoleAdmin(CoreRoles.TIMELOCK_CANCELLER, CoreRoles.GOVERNOR);
    }

    /// @notice creates a new role to be maintained
    /// @param role the new role id
    /// @param adminRole the admin role id for `role`
    /// @dev can also be used to update admin of existing role
    function createRole(
        bytes32 role,
        bytes32 adminRole
    ) external onlyRole(CoreRoles.GOVERNOR) {
        _setRoleAdmin(role, adminRole);
    }

    /// @notice batch granting of roles to various addresses
    /// @dev if msg.sender does not have admin role needed to grant any of the
    /// granted roles, the whole transaction reverts.
    function grantRoles(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external {
        assert(roles.length == accounts.length);
        for (uint256 i = 0; i < roles.length; i++) {
            _checkRole(getRoleAdmin(roles[i]));
            _grantRole(roles[i], accounts[i]);
        }
    }

    // AccessControlEnumerable is AccessControl, and also has the following functions :
    // hasRole(bytes32 role, address account) -> bool
    // getRoleAdmin(bytes32 role) -> bytes32
    // grantRole(bytes32 role, address account)
    // revokeRole(bytes32 role, address account)
    // renounceRole(bytes32 role, address account)
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {CoreRef} from "@src/core/CoreRef.sol";
import {CoreRoles} from "@src/core/CoreRoles.sol";
import {LendingTerm} from "@src/loan/LendingTerm.sol";
import {ERC20Gauges} from "@src/tokens/ERC20Gauges.sol";
import {ProfitManager} from "@src/governance/ProfitManager.sol";
import {ERC20MultiVotes} from "@src/tokens/ERC20MultiVotes.sol";

/** 
@title  GUILD ERC20 Token
@author eswak
@notice This is the governance token of the Ethereum Credit Guild.
    On deploy, this token is non-transferrable.
    During the non-transferrable period, GUILD can still be minted & burnt, only
    `transfer` and `transferFrom` are reverting.

    The gauge system is used to define debt ceilings on a set of lending terms.
    Lending terms can be whitelisted by adding a gauge for their address, if GUILD
    holders vote for these lending terms in the gauge system, the lending terms will
    have a non-zero debt ceiling, and borrowing will be available under these terms.

    When a lending term creates bad debt, a loss is notified in a gauge on this
    contract (`notifyGaugeLoss`). When a loss is notified, all the GUILD token weight voting
    for this gauge becomes non-transferable and can be permissionlessly slashed. Until the
    loss is realized (`applyGaugeLoss`), a user cannot transfer their locked tokens or
    decrease the weight they assign to the gauge that suffered a loss.
    Even when a loss occur, users can still transfer tokens with which they vote for gauges
    that did not suffer a loss.
*/
contract GuildToken is CoreRef, ERC20Burnable, ERC20Gauges, ERC20MultiVotes {
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(
        address _core
    )
        CoreRef(_core)
        ERC20("Ethereum Credit Guild - GUILD", "GUILD")
        ERC20Permit("Ethereum Credit Guild - GUILD")
    {}

    /*///////////////////////////////////////////////////////////////
                        VOTING MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Set `maxDelegates`, the maximum number of addresses any account can delegate voting power to.
    function setMaxDelegates(
        uint256 newMax
    ) external onlyCoreRole(CoreRoles.GUILD_GOVERNANCE_PARAMETERS) {
        _setMaxDelegates(newMax);
    }

    /// @notice Allow or disallow an address to delegate voting power to more addresses than `maxDelegates`.
    function setContractExceedMaxDelegates(
        address account,
        bool canExceedMax
    ) external onlyCoreRole(CoreRoles.GUILD_GOVERNANCE_PARAMETERS) {
        _setContractExceedMaxDelegates(account, canExceedMax);
    }

    /// @notice Set the lockup period after delegating votes
    function setDelegateLockupPeriod(
        uint256 newValue
    ) external onlyCoreRole(CoreRoles.GUILD_GOVERNANCE_PARAMETERS) {
        _setDelegateLockupPeriod(newValue);
    }

    /*///////////////////////////////////////////////////////////////
                        GAUGE MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    function addGauge(
        uint256 _type,
        address gauge
    ) external onlyCoreRole(CoreRoles.GAUGE_ADD) returns (uint256) {
        return _addGauge(_type, gauge);
    }

    function removeGauge(
        address gauge
    ) external onlyCoreRole(CoreRoles.GAUGE_REMOVE) {
        _removeGauge(gauge);
    }

    function setMaxGauges(
        uint256 max
    ) external onlyCoreRole(CoreRoles.GAUGE_PARAMETERS) {
        _setMaxGauges(max);
    }

    function setCanExceedMaxGauges(
        address who,
        bool can
    ) external onlyCoreRole(CoreRoles.GAUGE_PARAMETERS) {
        _setCanExceedMaxGauges(who, can);
    }

    /*///////////////////////////////////////////////////////////////
                        LOSS MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when a loss in a gauge is notified.
    event GaugeLoss(address indexed gauge, uint256 indexed when);
    /// @notice emitted when a loss in a gauge is applied (for each user).
    event GaugeLossApply(
        address indexed gauge,
        address indexed who,
        uint256 weight,
        uint256 when
    );

    /// @notice last block.timestamp when a loss occurred in a given gauge
    mapping(address => uint256) public lastGaugeLoss;

    /// @notice last block.timestamp when a user apply a loss that occurred in a given gauge
    mapping(address => mapping(address => uint256)) public lastGaugeLossApplied;

    /// @notice notify loss in a given gauge
    function notifyGaugeLoss(address gauge) external {
        require(_gauges.contains(gauge), "GuildToken: gauge not found");
        require(
            msg.sender == LendingTerm(gauge).profitManager(),
            "UNAUTHORIZED"
        );

        // save gauge loss
        lastGaugeLoss[gauge] = block.timestamp;
        emit GaugeLoss(gauge, block.timestamp);
    }

    /// @notice apply a loss that occurred in a given gauge
    /// anyone can apply the loss on behalf of anyone else
    function applyGaugeLoss(address gauge, address who) external {
        // check preconditions
        uint256 _lastGaugeLoss = lastGaugeLoss[gauge];
        uint256 _lastGaugeLossApplied = lastGaugeLossApplied[gauge][who];
        require(
            _lastGaugeLoss != 0 && _lastGaugeLossApplied < _lastGaugeLoss,
            "GuildToken: no loss to apply"
        );

        // read user weight allocated to the lossy gauge
        uint256 _userGaugeWeight = getUserGaugeWeight[who][gauge];

        // remove gauge weight allocation
        lastGaugeLossApplied[gauge][who] = block.timestamp;
        if (!_deprecatedGauges.contains(gauge)) {
            totalTypeWeight[gaugeType[gauge]] -= _userGaugeWeight;
            totalWeight -= _userGaugeWeight;
        }
        _decrementGaugeWeight(who, gauge, _userGaugeWeight);

        // apply loss
        _burn(who, uint256(_userGaugeWeight));
        emit GaugeLossApply(
            gauge,
            who,
            uint256(_userGaugeWeight),
            block.timestamp
        );
    }

    /*///////////////////////////////////////////////////////////////
                        TRANSFERABILITY
    //////////////////////////////////////////////////////////////*/

    /// @notice at deployment, tokens are not transferable (can only mint/burn).
    /// Governance can enable transfers with `enableTransfers()`.
    bool public transferable; // default = false

    /// @notice emitted when transfers are enabled.
    event TransfersEnabled(uint256 block, uint256 timestamp);

    /// @notice permanently enable token transfers.
    function enableTransfer() external onlyCoreRole(CoreRoles.GOVERNOR) {
        transferable = true;
        emit TransfersEnabled(block.number, block.timestamp);
    }

    /// @dev prevent transfers if they are not globally enabled.
    /// mint and burn (transfers to and from address 0) are accepted.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /* amount*/
    ) internal view override {
        require(
            transferable || from == address(0) || to == address(0),
            "GuildToken: transfers disabled"
        );
    }

    /// @dev prevent outbound token transfers (_decrementWeightUntilFree) and gauge weight decrease
    /// (decrementGauge, decrementGauges) for users who have an unrealized loss in a gauge, or if the
    /// gauge is currently using its allocated debt ceiling. To decrement gauge weight, guild holders
    /// might have to call loans if the debt ceiling is used.
    /// Also update the user profit index and claim rewards.
    function _decrementGaugeWeight(
        address user,
        address gauge,
        uint256 weight
    ) internal override {
        uint256 _lastGaugeLoss = lastGaugeLoss[gauge];
        uint256 _lastGaugeLossApplied = lastGaugeLossApplied[gauge][user];
        require(
            _lastGaugeLossApplied >= _lastGaugeLoss,
            "GuildToken: pending loss"
        );
        uint256 issuance = LendingTerm(gauge).issuance();
        if (isDeprecatedGauge(gauge)) {
            require(issuance == 0, "GuildToken: not all loans closed");
        }

        // update the user profit index and claim rewards
        ProfitManager(LendingTerm(gauge).profitManager()).claimGaugeRewards(
            user,
            gauge
        );

        // check if gauge is currently using its allocated debt ceiling.
        // To decrement gauge weight, guild holders might have to call loans if the debt ceiling is used.
        if (issuance != 0) {
            uint256 debtCeilingAfterDecrement = LendingTerm(gauge).debtCeiling(
                -int256(weight)
            );
            require(
                issuance <= debtCeilingAfterDecrement,
                "GuildToken: debt ceiling used"
            );
        }

        super._decrementGaugeWeight(user, gauge, weight);
    }

    /// @dev prevent weight increment for gauge if user has an unapplied loss.
    /// If the user has 0 weight (i.e. no loss to realize), allow incrementing
    /// gauge weight & update lastGaugeLossApplied to current time.
    /// Also update the user profit index an claim rewards.
    /// @dev note that users voting for a gauge that is not a proper lending term could result in this
    /// share of the user's tokens to be frozen, due to being unable to decrement weight.
    function _incrementGaugeWeight(
        address user,
        address gauge,
        uint256 weight
    ) internal override {
        uint256 _lastGaugeLoss = lastGaugeLoss[gauge];
        uint256 _lastGaugeLossApplied = lastGaugeLossApplied[gauge][user];
        if (getUserGaugeWeight[user][gauge] == 0) {
            lastGaugeLossApplied[gauge][user] = block.timestamp;
        } else {
            require(
                _lastGaugeLossApplied >= _lastGaugeLoss,
                "GuildToken: pending loss"
            );
        }

        ProfitManager(LendingTerm(gauge).profitManager()).claimGaugeRewards(
            user,
            gauge
        );

        super._incrementGaugeWeight(user, gauge, weight);
    }

    /*///////////////////////////////////////////////////////////////
                        MINT / BURN
    //////////////////////////////////////////////////////////////*/

    /// @notice mint new tokens to the target address
    function mint(
        address to,
        uint256 amount
    ) external onlyCoreRole(CoreRoles.GUILD_MINTER) {
        _mint(to, amount);
    }

    /*///////////////////////////////////////////////////////////////
                        Inheritance reconciliation
    //////////////////////////////////////////////////////////////*/

    function _burn(
        address from,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Gauges, ERC20MultiVotes) {
        _decrementWeightUntilFree(from, amount);
        _decrementVotesUntilFree(from, amount);
        // do not check delegate lockup when burning token
        // as this can be used to make it impossible for a user to be slashed
        // _checkDelegateLockupPeriod(from);
        ERC20._burn(from, amount);
    }

    function transfer(
        address to,
        uint256 amount
    )
        public
        virtual
        override(ERC20, ERC20Gauges, ERC20MultiVotes)
        returns (bool)
    {
        _decrementWeightUntilFree(msg.sender, amount);
        _decrementVotesUntilFree(msg.sender, amount);
        _checkDelegateLockupPeriod(msg.sender);
        return ERC20.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        public
        virtual
        override(ERC20, ERC20Gauges, ERC20MultiVotes)
        returns (bool)
    {
        _decrementWeightUntilFree(from, amount);
        _decrementVotesUntilFree(from, amount);
        _checkDelegateLockupPeriod(from);
        return ERC20.transferFrom(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {CoreRef} from "@src/core/CoreRef.sol";
import {CoreRoles} from "@src/core/CoreRoles.sol";
import {LendingTerm} from "@src/loan/LendingTerm.sol";
import {ProfitManager} from "@src/governance/ProfitManager.sol";

/// @notice Auction House contract of the Ethereum Credit Guild,
/// where collateral of borrowers is auctioned to cover their CREDIT debt.
contract AuctionHouse is CoreRef {
    /// @notice emitted when au action starts
    event AuctionStart(
        uint256 indexed when,
        bytes32 indexed loanId,
        address collateralToken,
        uint256 collateralAmount,
        uint256 callDebt
    );
    /// @notice emitted when au anction ends
    event AuctionEnd(
        uint256 indexed when,
        bytes32 indexed loanId,
        address collateralToken,
        uint256 collateralSold,
        uint256 debtRecovered
    );

    /// @notice number of seconds before the midpoint of the auction, at which time the
    /// mechanism switches from "offer an increasing amount of collateral" to
    /// "ask a decreasing amount of debt".
    uint256 public immutable midPoint;

    /// @notice maximum duration of auctions, in seconds.
    /// with a midpoint of 650 (10m50s) and an auction duration of 30min, and a block every
    /// 13s, first phase will last around 50 blocks and each block will offer an additional
    /// 1/(650/13)=2% of the collateral during the first phase. During the second phase,
    /// every block will ask 1/((1800-650)/13)=1.13% less CREDIT in each block.
    uint256 public immutable auctionDuration;

    /// @notice starting percentage of collateral offered, expressed as a percentage
    /// with 18 decimals.
    uint256 public immutable startCollateralOffered;

    struct Auction {
        uint48 startTime;
        uint48 endTime;
        address lendingTerm;
        uint256 collateralAmount;
        uint256 callDebt;
        uint256 callCreditMultiplier;
    }

    /// @notice the list of all auctions that existed or are still active.
    /// key is the loanId for which the auction has been created.
    /// @dev see public getAuction(loanId) getter.
    mapping(bytes32 => Auction) internal auctions;

    /// @notice number of auctions currently in progress
    uint256 public nAuctionsInProgress;

    constructor(
        address _core,
        uint256 _midPoint,
        uint256 _auctionDuration,
        uint256 _startCollateralOffered
    ) CoreRef(_core) {
        require(_midPoint < _auctionDuration, "AuctionHouse: invalid params");
        midPoint = _midPoint;
        auctionDuration = _auctionDuration;
        startCollateralOffered = _startCollateralOffered;
    }

    /// @notice get a full auction structure from storage
    function getAuction(bytes32 loanId) external view returns (Auction memory) {
        return auctions[loanId];
    }

    /// @notice start the auction of the collateral of a loan, to be exchanged for CREDIT,
    /// in order to pay the debt of a loan.
    /// @param loanId the ID of the loan which collateral is auctioned
    function startAuction(bytes32 loanId) external {
        // check that caller is a lending term that still has PnL reporting role
        require(
            core().hasRole(CoreRoles.GAUGE_PNL_NOTIFIER, msg.sender),
            "AuctionHouse: invalid caller"
        );

        // check the loan exists in calling lending term and has been called in the current block
        LendingTerm.Loan memory loan = LendingTerm(msg.sender).getLoan(loanId);
        require(
            loan.callTime == block.timestamp,
            "AuctionHouse: loan previously called"
        );

        // check auction for this loan has not already been created
        require(
            auctions[loanId].startTime == 0,
            "AuctionHouse: auction exists"
        );

        // save auction in state
        auctions[loanId] = Auction({
            startTime: uint48(block.timestamp),
            endTime: 0,
            lendingTerm: msg.sender,
            collateralAmount: loan.collateralAmount,
            callDebt: loan.callDebt,
            callCreditMultiplier: ProfitManager(
                LendingTerm(msg.sender).profitManager()
            ).creditMultiplier()
        });
        nAuctionsInProgress++;

        // emit event
        emit AuctionStart(
            block.timestamp,
            loanId,
            LendingTerm(msg.sender).collateralToken(),
            loan.collateralAmount,
            loan.callDebt
        );
    }

    /// @notice Get the bid details for an active auction.
    /// During the first half of the auction, an increasing amount of the collateral is offered, for the full CREDIT amount.
    /// During the second half of the action, all collateral is offered, for a decreasing CREDIT amount.
    function getBidDetail(
        bytes32 loanId
    ) public view returns (uint256 collateralReceived, uint256 creditAsked) {
        // check the auction for this loan exists
        uint256 _startTime = auctions[loanId].startTime;
        require(_startTime != 0, "AuctionHouse: invalid auction");

        // check the auction for this loan isn't ended
        require(auctions[loanId].endTime == 0, "AuctionHouse: auction ended");

        // assertion should never fail because when an auction is created,
        // block.timestamp is recorded as the auction start time, and we check in previous
        // lines that start time != 0, so the auction has started.
        assert(block.timestamp >= _startTime);

        // first phase of the auction, where more and more collateral is offered
        if (block.timestamp < _startTime + midPoint) {
            // ask for the full debt
            creditAsked = auctions[loanId].callDebt;

            // compute amount of collateral received
            uint256 elapsed = block.timestamp - _startTime; // [0, midPoint[
            uint256 _collateralAmount = auctions[loanId].collateralAmount; // SLOAD
            uint256 minCollateralReceived = (startCollateralOffered *
                _collateralAmount) / 1e18;
            uint256 remainingCollateral = _collateralAmount -
                minCollateralReceived;
            collateralReceived =
                minCollateralReceived +
                (remainingCollateral * elapsed) /
                midPoint;
        }
        // second phase of the auction, where less and less CREDIT is asked
        else if (block.timestamp < _startTime + auctionDuration) {
            // receive the full collateral
            collateralReceived = auctions[loanId].collateralAmount;

            // compute amount of CREDIT to ask
            uint256 PHASE_2_DURATION = auctionDuration - midPoint;
            uint256 elapsed = block.timestamp - _startTime - midPoint; // [0, PHASE_2_DURATION[
            uint256 _callDebt = auctions[loanId].callDebt; // SLOAD
            creditAsked = _callDebt - (_callDebt * elapsed) / PHASE_2_DURATION;
        }
        // second phase fully elapsed, anyone can receive the full collateral and give 0 CREDIT
        // in practice, somebody should have taken the arb before we reach this condition, and
        // there are conditions in bid() & forgive() to prevent this from happening.
        else {
            // receive the full collateral
            collateralReceived = auctions[loanId].collateralAmount;
            //creditAsked = 0; // implicit
        }

        // apply eventual creditMultiplier updates
        uint256 creditMultiplier = ProfitManager(
            LendingTerm(auctions[loanId].lendingTerm).profitManager()
        ).creditMultiplier();
        creditAsked =
            (creditAsked * auctions[loanId].callCreditMultiplier) /
            creditMultiplier;
    }

    /// @notice bid for an active auction
    /// @dev as a bidder, you must approve CREDIT tokens on the LendingTerm contract associated
    /// with the loan `getAuction(loanId).lendingTerm`, not on the AuctionHouse itself.
    function bid(bytes32 loanId) external {
        // this view function will revert if the auction is not started,
        // or if the auction is already ended.
        (uint256 collateralReceived, uint256 creditAsked) = getBidDetail(
            loanId
        );
        require(creditAsked != 0, "AuctionHouse: cannot bid 0");

        // close the auction in state
        auctions[loanId].endTime = uint48(block.timestamp);
        nAuctionsInProgress--;

        // notify LendingTerm of auction result
        address _lendingTerm = auctions[loanId].lendingTerm;
        LendingTerm(_lendingTerm).onBid(
            loanId,
            msg.sender,
            auctions[loanId].collateralAmount - collateralReceived, // collateralToBorrower
            collateralReceived, // collateralToBidder
            creditAsked // creditFromBidder
        );

        // emit event
        emit AuctionEnd(
            block.timestamp,
            loanId,
            LendingTerm(_lendingTerm).collateralToken(),
            collateralReceived, // collateralSold
            creditAsked // debtRecovered
        );
    }

    /// @notice forgive a loan, by marking the debt as a total loss
    /// @dev this is meant to be used when an auction concludes without anyone bidding,
    /// even if 0 CREDIT is asked in return. This situation could arise
    /// if collateral assets are frozen within the lending term contract.
    function forgive(bytes32 loanId) external {
        // this view function will revert if the auction is not started,
        // or if the auction is already ended.
        (, uint256 creditAsked) = getBidDetail(loanId);
        require(creditAsked == 0, "AuctionHouse: ongoing auction");

        // close the auction in state
        auctions[loanId].endTime = uint48(block.timestamp);
        nAuctionsInProgress--;

        // notify LendingTerm of auction result
        address _lendingTerm = auctions[loanId].lendingTerm;
        LendingTerm(_lendingTerm).onBid(
            loanId,
            msg.sender,
            0, // collateralToBorrower
            0, // collateralToBidder
            0 // creditFromBidder
        );

        // emit event
        emit AuctionEnd(
            block.timestamp,
            loanId,
            LendingTerm(_lendingTerm).collateralToken(),
            0, // collateralSold
            0 // debtRecovered
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {CoreRef} from "@src/core/CoreRef.sol";
import {CoreRoles} from "@src/core/CoreRoles.sol";
import {RateLimitedV2} from "@src/rate-limits/RateLimitedV2.sol";

interface IERC20Mintable {
    function mint(address to, uint256 amount) external;
}

/// @notice contract to mint tokens on a rate limit.
contract RateLimitedMinter is RateLimitedV2 {
    /// @notice the reference to token
    address public immutable token;

    /// @notice role used to access control on mint/replenishBuffer
    bytes32 public immutable role;

    /// @param _core reference to the core smart contract
    /// @param _token reference to the token to mint
    /// @param _role role used to check access control
    /// @param _maxRateLimitPerSecond maximum rate limit per second that governance can set
    /// @param _rateLimitPerSecond starting rate limit per second for minting
    /// @param _bufferCap cap on buffer size for this rate limited instance
    constructor(
        address _core,
        address _token,
        bytes32 _role,
        uint256 _maxRateLimitPerSecond,
        uint128 _rateLimitPerSecond,
        uint128 _bufferCap
    )
        CoreRef(_core)
        RateLimitedV2(_maxRateLimitPerSecond, _rateLimitPerSecond, _bufferCap)
    {
        token = _token;
        role = _role;
    }

    /// @notice Mint new tokens.
    /// Pausable and depletes the buffer, reverts if buffer is used.
    /// @param to the recipient address of the minted tokens.
    /// @param amount the amount of tokens to mint.
    function mint(address to, uint256 amount) external onlyCoreRole(role) {
        _depleteBuffer(amount); /// check and effects
        IERC20Mintable(token).mint(to, amount); /// interactions
    }

    /// @notice replenish the buffer.
    /// This can be used when tokens are burnt, for instance.
    /// @param amount of tokens to replenish buffer by
    function replenishBuffer(uint256 amount) external onlyCoreRole(role) {
        _replenishBuffer(amount); /// effects
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/cryptography/EIP712.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
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

// SPDX-License-Identifier: MIT
// Voting logic inspired by OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity 0.8.13;

import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {SafeCastLib} from "@solmate/src/utils/SafeCastLib.sol";

/**
@title  ERC20 Multi-Delegation Voting contract
@notice an ERC20 extension which allows delegations to multiple delegatees up to a user's balance on a given block.
@dev    SECURITY NOTES: `maxDelegates` is a critical variable to protect against gas DOS attacks upon token transfer. 
        This must be low enough to allow complicated transactions to fit in a block.
@dev This contract was originally published as part of TribeDAO's flywheel-v2 repo, please see:
    https://github.com/fei-protocol/flywheel-v2/blob/main/src/token/ERC20MultiVotes.sol
    The original version was included in 2 audits :
    - https://code4rena.com/reports/2022-04-xtribe/
    - https://consensys.net/diligence/audits/2022/04/tribe-dao-flywheel-v2-xtribe-xerc4626/
    ECG made the following changes to the original flywheel-v2 version :
    - Does not inherit Solmate's Auth (all requiresAuth functions are now internal, see below)
        -> This contract is abstract, and permissioned public functions can be added in parent.
        -> permissioned public functions to add in parent:
            - function setMaxDelegates(uint256) external
            - function setContractExceedMaxDelegates(address,bool) external
    - Remove public setMaxDelegates(uint256) requiresAuth method 
        ... Add internal _setMaxDelegates(uint256) method
    - Remove public setContractExceedMaxDelegates(address,bool) requiresAuth method
        ... Add internal _setContractExceedMaxDelegates(address,bool) method
    - Import OpenZeppelin ERC20Permit & EnumerableSet instead of Solmate's
    - Update error management style (use require + messages instead of Solidity errors)
    - Implement C4 audit fix for [L-01] & [N-06].
    - Add optional lockup period upon delegation
*/
abstract contract ERC20MultiVotes is ERC20Permit {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeCastLib for *;

    /*///////////////////////////////////////////////////////////////
                        VOTE CALCULATION LOGIC
    //////////////////////////////////////////////////////////////*/

    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    /// @notice votes checkpoint list per user.
    mapping(address => Checkpoint[]) private _checkpoints;

    /// @notice Get the `pos`-th checkpoint for `account`.
    function checkpoints(
        address account,
        uint32 pos
    ) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /// @notice Get number of checkpoints for `account`.
    function numCheckpoints(
        address account
    ) public view virtual returns (uint32) {
        return _checkpoints[account].length.safeCastTo32();
    }

    /**
     * @notice Gets the amount of unallocated votes for `account`.
     * @param account the address to get free votes of.
     * @return the amount of unallocated votes.
     */
    function freeVotes(address account) public view virtual returns (uint256) {
        return balanceOf(account) - userDelegatedVotes[account];
    }

    /**
     * @notice Gets the current votes balance for `account`.
     * @param account the address to get votes of.
     * @return the amount of votes.
     */
    function getVotes(address account) public view virtual returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @notice Retrieve the number of votes for `account` at the end of `blockNumber`.
     * @param account the address to get votes of.
     * @param blockNumber the block to calculate votes for.
     * @return the amount of votes.
     */
    function getPastVotes(
        address account,
        uint256 blockNumber
    ) public view virtual returns (uint256) {
        require(
            blockNumber < block.number,
            "ERC20MultiVotes: not a past block"
        );
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /// @dev Lookup a value in a list of (sorted) checkpoints.
    function _checkpointsLookup(
        Checkpoint[] storage ckpts,
        uint256 blockNumber
    ) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /*///////////////////////////////////////////////////////////////
                        ADMIN OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when updating the delegate lockup time
    event DelegateLockupUpdate(uint256 oldValue, uint256 newValue);

    /// @notice the period in seconds after a delegation where tokens
    /// cannot be transferred
    uint256 public delegateLockupPeriod;

    /// @notice set the delegate lockup period.
    function _setDelegateLockupPeriod(uint256 newValue) internal {
        uint256 oldValue = delegateLockupPeriod;
        delegateLockupPeriod = newValue;

        emit DelegateLockupUpdate(oldValue, newValue);
    }

    /// @notice hook to check lockup period on transfer
    function _checkDelegateLockupPeriod(address user) internal view {
        uint256 _delegateLockupPeriod = delegateLockupPeriod;
        if (_delegateLockupPeriod != 0) {
            uint256 _lastDelegation = lastDelegation[user];
            if (_lastDelegation != 0) {
                require(
                    block.timestamp > _lastDelegation + _delegateLockupPeriod,
                    "ERC20MultiVotes: delegate lockup period"
                );
            }
        }
    }

    /// @notice emitted when updating the maximum amount of delegates per user
    event MaxDelegatesUpdate(uint256 oldMaxDelegates, uint256 newMaxDelegates);

    /// @notice emitted when updating the canContractExceedMaxDelegates flag for an account
    event CanContractExceedMaxDelegatesUpdate(
        address indexed account,
        bool canContractExceedMaxDelegates
    );

    /// @notice the maximum amount of delegates for a user at a given time
    uint256 public maxDelegates;

    /// @notice an approve list for contracts to go above the max delegate limit.
    mapping(address => bool) public canContractExceedMaxDelegates;

    /// @notice set the new max delegates per user.
    /// Does not prevent delegation updates to existing delegates, and does not
    /// force undelegation to existing delegates, if the maxDelegates is set to
    /// a lower value and delegators have existing delegatees.
    function _setMaxDelegates(uint256 newMax) internal {
        uint256 oldMax = maxDelegates;
        maxDelegates = newMax;

        emit MaxDelegatesUpdate(oldMax, newMax);
    }

    /// @notice set the canContractExceedMaxDelegates flag for an account.
    function _setContractExceedMaxDelegates(
        address account,
        bool canExceedMax
    ) internal {
        require(
            !canExceedMax || account.code.length != 0,
            "ERC20MultiVotes: not a smart contract"
        ); // can only approve contracts

        canContractExceedMaxDelegates[account] = canExceedMax;

        emit CanContractExceedMaxDelegatesUpdate(account, canExceedMax);
    }

    /*///////////////////////////////////////////////////////////////
                        DELEGATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when a `delegator` delegates `amount` votes to `delegate`.
    event Delegation(
        address indexed delegator,
        address indexed delegate,
        uint256 amount
    );

    /// @dev Emitted when a `delegator` undelegates `amount` votes from `delegate`.
    event Undelegation(
        address indexed delegator,
        address indexed delegate,
        uint256 amount
    );

    /// @dev Emitted when a token transfer or delegate change results in changes to an account's voting power.
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /// @notice An event that is emitted when an account changes its delegate
    /// @dev this is used for backward compatibility with OZ interfaces for ERC20Votes and ERC20VotesComp.
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice mapping from a delegator and delegatee to the delegated amount.
    mapping(address => mapping(address => uint256))
        private _delegatesVotesCount;

    /// @notice mapping from a delegator to the total number of delegated votes.
    mapping(address => uint256) public userDelegatedVotes;

    /// @notice mapping from a delegator to their last timestamp of delegation.
    mapping(address => uint256) public lastDelegation;

    /// @notice list of delegates per user.
    mapping(address => EnumerableSet.AddressSet) private _delegates;

    /**
     * @notice Get the amount of votes currently delegated by `delegator` to `delegatee`.
     * @param delegator the account which is delegating votes to `delegatee`.
     * @param delegatee the account receiving votes from `delegator`.
     * @return the total amount of votes delegated to `delegatee` by `delegator`
     */
    function delegatesVotesCount(
        address delegator,
        address delegatee
    ) public view virtual returns (uint256) {
        return _delegatesVotesCount[delegator][delegatee];
    }

    /**
     * @notice Get the list of delegates from `delegator`.
     * @param delegator the account which is delegating votes to delegates.
     * @return the list of delegated accounts.
     */
    function delegates(
        address delegator
    ) public view returns (address[] memory) {
        return _delegates[delegator].values();
    }

    /**
     * @notice Checks whether delegatee is in the `delegator` mapping.
     * @param delegator the account which is delegating votes to delegates.
     * @param delegatee the account which receives votes from delegate.
     * @return true or false
     */
    function containsDelegate(
        address delegator,
        address delegatee
    ) public view returns (bool) {
        return _delegates[delegator].contains(delegatee);
    }

    /**
     * @notice Get the number of delegates from `delegator`.
     * @param delegator the account which is delegating votes to delegates.
     * @return the number of delegated accounts.
     */
    function delegateCount(address delegator) public view returns (uint256) {
        return _delegates[delegator].length();
    }

    /**
     * @notice Delegate `amount` votes from the sender to `delegatee`.
     * @param delegatee the receiver of votes.
     * @param amount the amount of votes received.
     * @dev requires "freeVotes(msg.sender) > amount" and will not exceed max delegates
     */
    function incrementDelegation(
        address delegatee,
        uint256 amount
    ) public virtual {
        _incrementDelegation(msg.sender, delegatee, amount);
    }

    /**
     * @notice Undelegate `amount` votes from the sender from `delegatee`.
     * @param delegatee the receivier of undelegation.
     * @param amount the amount of votes taken away.
     */
    function undelegate(address delegatee, uint256 amount) public virtual {
        _undelegate(msg.sender, delegatee, amount);
    }

    /**
     * @notice Delegate all votes `newDelegatee`. First undelegates from an existing delegate. If `newDelegatee` is zero, only undelegates.
     * @param newDelegatee the receiver of votes.
     * @dev undefined for `delegateCount(msg.sender) > 1`
     * NOTE This is meant for backward compatibility with the `ERC20Votes` and `ERC20VotesComp` interfaces from OpenZeppelin.
     */
    function delegate(address newDelegatee) external virtual {
        _delegate(msg.sender, newDelegatee);
    }

    function _delegate(
        address delegator,
        address newDelegatee
    ) internal virtual {
        uint256 count = delegateCount(delegator);

        // undefined behavior for delegateCount > 1
        require(count < 2, "ERC20MultiVotes: delegation error");

        address oldDelegatee;
        // if already delegated, undelegate first
        if (count == 1) {
            oldDelegatee = _delegates[delegator].at(0);
            _undelegate(
                delegator,
                oldDelegatee,
                _delegatesVotesCount[delegator][oldDelegatee]
            );
        }

        // redelegate only if newDelegatee is not empty
        if (newDelegatee != address(0)) {
            _incrementDelegation(delegator, newDelegatee, freeVotes(delegator));
        }
        emit DelegateChanged(delegator, oldDelegatee, newDelegatee);
    }

    function _incrementDelegation(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal virtual {
        // Require freeVotes exceed the delegation size
        uint256 free = freeVotes(delegator);
        require(
            delegatee != address(0) && free >= amount,
            "ERC20MultiVotes: delegation error"
        );

        bool newDelegate = _delegates[delegator].add(delegatee); // idempotent add
        require(
            !newDelegate ||
                delegateCount(delegator) <= maxDelegates ||
                canContractExceedMaxDelegates[delegator],
            "ERC20MultiVotes: delegation error"
        );

        _delegatesVotesCount[delegator][delegatee] += amount;
        userDelegatedVotes[delegator] += amount;
        lastDelegation[delegator] = block.timestamp;

        emit Delegation(delegator, delegatee, amount);
        _writeCheckpoint(delegatee, _add, amount);
    }

    function _undelegate(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal virtual {
        uint256 newDelegates = _delegatesVotesCount[delegator][delegatee] -
            amount;

        if (newDelegates == 0) {
            require(_delegates[delegator].remove(delegatee));
        }

        _delegatesVotesCount[delegator][delegatee] = newDelegates;
        userDelegatedVotes[delegator] -= amount;

        emit Undelegation(delegator, delegatee, amount);
        _writeCheckpoint(delegatee, _subtract, amount);
    }

    function _writeCheckpoint(
        address delegatee,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private {
        Checkpoint[] storage ckpts = _checkpoints[delegatee];

        uint256 pos = ckpts.length;
        uint256 oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        uint256 newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = newWeight.safeCastTo224();
        } else {
            ckpts.push(
                Checkpoint({
                    fromBlock: block.number.safeCastTo32(),
                    votes: newWeight.safeCastTo224()
                })
            );
        }
        emit DelegateVotesChanged(delegatee, oldWeight, newWeight);
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /*///////////////////////////////////////////////////////////////
                             ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// NOTE: any "removal" of tokens from a user requires freeVotes(user) < amount.
    /// _decrementVotesUntilFree is called as a greedy algorithm to free up votes.
    /// It may be more gas efficient to free weight before burning or transferring tokens.

    function _burn(address from, uint256 amount) internal virtual override {
        _decrementVotesUntilFree(from, amount);
        _checkDelegateLockupPeriod(from);
        super._burn(from, amount);
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _decrementVotesUntilFree(msg.sender, amount);
        _checkDelegateLockupPeriod(msg.sender);
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _decrementVotesUntilFree(from, amount);
        _checkDelegateLockupPeriod(from);
        return super.transferFrom(from, to, amount);
    }

    /// a greedy algorithm for freeing votes before a token burn/transfer
    /// frees up entire delegates, so likely will free more than `votes`
    function _decrementVotesUntilFree(address user, uint256 votes) internal {
        uint256 userFreeVotes = freeVotes(user);

        // early return if already free
        if (userFreeVotes >= votes) return;

        // cache total for batch updates
        uint256 totalFreed;

        // Loop through all delegates
        address[] memory delegateList = _delegates[user].values();

        // Free delegates until through entire list or under votes amount
        uint256 size = delegateList.length;
        for (
            uint256 i = 0;
            i < size && (userFreeVotes + totalFreed) < votes;
            i++
        ) {
            address delegatee = delegateList[i];
            uint256 delegateVotes = _delegatesVotesCount[user][delegatee];
            if (delegateVotes != 0) {
                totalFreed += delegateVotes;

                require(_delegates[user].remove(delegatee)); // Remove from set. Should never fail.

                _delegatesVotesCount[user][delegatee] = 0;

                _writeCheckpoint(delegatee, _subtract, delegateVotes);
                emit Undelegation(user, delegatee, delegateVotes);
            }
        }

        userDelegatedVotes[user] -= totalFreed;
    }

    /*///////////////////////////////////////////////////////////////
                             EIP-712 LOGIC
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @dev this consumes the same nonce as permit(), so the order of call matters.
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(
            block.timestamp <= expiry,
            "ERC20MultiVotes: signature expired"
        );
        address signer = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _domainSeparatorV4(),
                    keccak256(
                        abi.encode(
                            DELEGATION_TYPEHASH,
                            delegatee,
                            nonce,
                            expiry
                        )
                    )
                )
            ),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20MultiVotes: invalid nonce");
        require(signer != address(0));
        _delegate(signer, delegatee);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeCastLib} from "@solmate/src/utils/SafeCastLib.sol";

/** 
@title  An ERC20 with rebase capabilities. Anyone can sacrifice tokens to rebase up the balance
        of all addresses that are currently rebasing.
@author eswak
@notice This contract is meant to be used to distribute rewards proportionately to all holders of
        a token, for instance to distribute buybacks or income generated by a protocol.

        Anyone can subscribe to rebasing by calling `enterRebase()`, and unsubcribe with `exitRebase()`.
        Anyone can burn tokens they own to `distribute(uint256)` proportionately to rebasing addresses.

        The following conditions are always met :
        ```
        totalSupply() == nonRebasingSupply() + rebasingSupply()
        sum of balanceOf(x) == totalSupply() [+= rounding down errors of 1 wei for each balanceOf]
        ```

        Internally, when a user subscribes to the rebase, their balance is converted to a number of
        shares, and the total number of shares is updated. When a user unsubscribes, their shares are
        converted back to a balance, and the total number of shares is updated.

        On each distribution, the share price of rebasing tokens is updated to reflect the new value
        of rebasing shares. The formula is as follow :

        ```
        newSharePrice = oldSharePrice * (rebasingSupply + amount) / rebasingSupply
        ```

        If the rebasingSupply is 0 (nobody subscribed to rebasing), the tokens distributed are burnt
        but nobody benefits for the share price increase, since the share price cannot be updated.

        /!\ The first user subscribing to rebase should have a meaningful balance in order to avoid
        share price manipulation (see hundred finance exploit).
        It is advised to keep a minimum balance rebasing at all times, for instance with a small
        rebasing balance held by the deployer address or address(0) or the token itself.
*/
abstract contract ERC20RebaseDistributor is ERC20 {
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an `account` enters rebasing.
    event RebaseEnter(address indexed account, uint256 indexed timestamp);
    /// @notice Emitted when an `account` exits rebasing.
    event RebaseExit(address indexed account, uint256 indexed timestamp);
    /// @notice Emitted when an `amount` of tokens is distributed by `source` to the rebasing accounts.
    event RebaseDistribution(
        address indexed source,
        uint256 indexed timestamp,
        uint256 amountDistributed,
        uint256 totalPendingDistributions,
        uint256 amountRebasing
    );
    /// @notice Emitted when an `amount` of tokens is realized as rebase rewards for `account`.
    /// @dev `totalSupply()`, `rebasingSupply()`, and `balanceOf()` reflect the rebase rewards
    /// in real time, but the internal storage only realizes rebase rewards if the user has an
    /// interaction with the token contract in one of the following functions:
    /// - exitRebase()
    /// - burn()
    /// - mint()
    /// - transfer() received or sent
    /// - transferFrom() received or sent
    event RebaseReward(
        address indexed account,
        uint256 indexed timestamp,
        uint256 amount
    );

    /*///////////////////////////////////////////////////////////////
                            INTERNAL STATE
    ///////////////////////////////////////////////////////////////*/

    struct RebasingState {
        uint8 isRebasing;
        uint248 nShares;
    }

    /// @notice For internal accounting. Number of rebasing shares for each rebasing accounts. 0 if account is not rebasing.
    mapping(address => RebasingState) internal rebasingState;

    /// @notice For internal accounting. Total number of rebasing shares
    uint256 internal totalRebasingShares;

    /// @notice The starting share price for rebasing addresses.
    /// @dev rounding errors start to appear when balances of users are near `rebasingSharePrice()`,
    /// due to rounding down in the number of shares attributed, and rounding down in the number of
    /// tokens per share. We use a high base to ensure no crazy rounding errors happen at runtime
    /// (balances of users would have to be > START_REBASING_SHARE_PRICE for rounding errors to start to materialize).
    uint256 internal constant START_REBASING_SHARE_PRICE = 1e30;

    /// @notice share price increase and pending rebase rewards from distribute() are
    /// interpolated linearly over a period of DISTRIBUTION_PERIOD seconds after a distribution.
    uint256 public constant DISTRIBUTION_PERIOD = 30 days;

    struct InterpolatedValue {
        uint32 lastTimestamp;
        uint224 lastValue;
        uint32 targetTimestamp;
        uint224 targetValue;
    }

    /// @notice For internal accounting. Number of tokens per share for the rebasing supply.
    /// Starts at START_REBASING_SHARE_PRICE and goes up only.
    InterpolatedValue internal __rebasingSharePrice =
        InterpolatedValue({
            lastTimestamp: SafeCastLib.safeCastTo32(block.timestamp),
            lastValue: uint224(START_REBASING_SHARE_PRICE), // safe initial value
            targetTimestamp: SafeCastLib.safeCastTo32(block.timestamp),
            targetValue: uint224(START_REBASING_SHARE_PRICE) // safe initial value
        });

    /// @notice For internal accounting. Number of tokens distributed to rebasing addresses that have not
    /// yet been materialized by a movement in the rebasing addresses.
    InterpolatedValue internal __unmintedRebaseRewards =
        InterpolatedValue({
            lastTimestamp: SafeCastLib.safeCastTo32(block.timestamp),
            lastValue: 0,
            targetTimestamp: SafeCastLib.safeCastTo32(block.timestamp),
            targetValue: 0
        });

    /*///////////////////////////////////////////////////////////////
                            INTERNAL UTILS
    ///////////////////////////////////////////////////////////////*/

    /// @notice get the current value of an interpolated value
    function interpolatedValue(
        InterpolatedValue memory val
    ) internal view returns (uint256) {
        // load state
        uint256 lastTimestamp = uint256(val.lastTimestamp); // safe upcast
        uint256 lastValue = uint256(val.lastValue); // safe upcast
        uint256 targetTimestamp = uint256(val.targetTimestamp); // safe upcast
        uint256 targetValue = uint256(val.targetValue); // safe upcast

        // interpolate increase over period
        if (block.timestamp >= targetTimestamp) {
            // if period is passed, return target value
            return targetValue;
        } else {
            // block.timestamp is within [lastTimestamp, targetTimestamp[
            uint256 elapsed = block.timestamp - lastTimestamp;
            uint256 delta = targetValue - lastValue;
            return
                lastValue +
                (delta * elapsed) /
                (targetTimestamp - lastTimestamp);
        }
    }

    /// @notice called to update the number of rebasing shares.
    /// This can happen in enterRebase() or exitRebase().
    /// If the number of shares is updated during the interpolation, the target share price
    /// of the interpolation should be changed to reflect the reduced or increased number of shares
    /// and keep a constant rebasing supply value (current & target).
    function updateTotalRebasingShares(
        uint256 currentRebasingSharePrice,
        int256 sharesDelta
    ) internal {
        if (sharesDelta == 0) return;
        uint256 sharesBefore = totalRebasingShares;
        uint256 sharesAfter;
        if (sharesDelta > 0) {
            sharesAfter = sharesBefore + uint256(sharesDelta);
        } else {
            uint256 shareDecrease = uint256(-sharesDelta);
            if (shareDecrease < sharesBefore) {
                unchecked {
                    sharesAfter = sharesBefore - shareDecrease;
                }
            }
            // else sharesAfter is 0
        }
        totalRebasingShares = sharesAfter;

        // reset interpolation & share price if going to 0 rebasing supply
        /// @dev this resets the contract to its initial state, and is only possible
        /// if all users have exited rebase.
        if (sharesAfter == 0) {
            __rebasingSharePrice = InterpolatedValue({
                lastTimestamp: SafeCastLib.safeCastTo32(block.timestamp), // now
                lastValue: uint224(START_REBASING_SHARE_PRICE), // safe initial value
                targetTimestamp: SafeCastLib.safeCastTo32(block.timestamp), // now
                targetValue: uint224(START_REBASING_SHARE_PRICE) // safe initial value
            });
            __unmintedRebaseRewards = InterpolatedValue({
                lastTimestamp: SafeCastLib.safeCastTo32(block.timestamp),
                lastValue: 0,
                targetTimestamp: SafeCastLib.safeCastTo32(block.timestamp),
                targetValue: 0
            });
            return;
        }

        // when total shares is multiplied by x, the remaining share price change ("delta" below)
        // should be multiplied by 1/x, e.g. going from a share price of 1.0 to 1.5, and current
        // value is 1.25, the remaining share price change "delta" is 0.25.
        // if the rebasing supply 2x, the share price change should 0.5x to 0.125.
        // at the end of the interpolation period, the share price will be 1.375.
        InterpolatedValue memory val = __rebasingSharePrice;
        uint256 delta = uint256(val.targetValue) - currentRebasingSharePrice;
        if (delta != 0) {
            uint256 percentChange = (sharesAfter * START_REBASING_SHARE_PRICE) /
                sharesBefore;
            uint256 targetNewSharePrice = currentRebasingSharePrice +
                (delta * START_REBASING_SHARE_PRICE) /
                percentChange;
            __rebasingSharePrice = InterpolatedValue({
                lastTimestamp: SafeCastLib.safeCastTo32(block.timestamp), // now
                lastValue: SafeCastLib.safeCastTo224(currentRebasingSharePrice), // current value
                targetTimestamp: val.targetTimestamp, // unchanged
                targetValue: SafeCastLib.safeCastTo224(targetNewSharePrice) // adjusted target
            });
        }
    }

    /// @notice get the current rebasing share price
    function rebasingSharePrice() internal view returns (uint256) {
        return interpolatedValue(__rebasingSharePrice);
    }

    /// @notice get the current unminted rebase rewards
    function unmintedRebaseRewards() internal view returns (uint256) {
        return interpolatedValue(__unmintedRebaseRewards);
    }

    /// @notice convert a balance to a number of shares
    function _balance2shares(
        uint256 balance,
        uint256 sharePrice
    ) internal pure returns (uint256) {
        return (balance * START_REBASING_SHARE_PRICE) / sharePrice;
    }

    /// @notice convert a number of shares to a balance
    function _shares2balance(
        uint256 shares,
        uint256 sharePrice,
        uint256 deltaBalance,
        uint256 minBalance
    ) internal pure returns (uint256) {
        uint256 rebasedBalance = (shares * sharePrice) /
            START_REBASING_SHARE_PRICE +
            deltaBalance;
        if (rebasedBalance < minBalance) {
            rebasedBalance = minBalance;
        }
        return rebasedBalance;
    }

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL API
    ///////////////////////////////////////////////////////////////*/

    /// @notice Enter rebasing supply. All subsequent distributions will increase the balance
    /// of `msg.sender` proportionately.
    function enterRebase() external {
        require(
            rebasingState[msg.sender].isRebasing == 0,
            "ERC20RebaseDistributor: already rebasing"
        );
        _enterRebase(msg.sender);
    }

    function _enterRebase(address account) internal {
        uint256 balance = ERC20.balanceOf(account);
        uint256 currentRebasingSharePrice = rebasingSharePrice();
        uint256 shares = _balance2shares(balance, currentRebasingSharePrice);
        rebasingState[account] = RebasingState({
            isRebasing: 1,
            nShares: uint248(shares)
        });
        updateTotalRebasingShares(currentRebasingSharePrice, int256(shares));
        emit RebaseEnter(account, block.timestamp);
    }

    /// @notice Exit rebasing supply. All unminted rebasing rewards are physically minted to the user,
    /// and they won't be affected by rebases anymore.
    function exitRebase() external {
        require(
            rebasingState[msg.sender].isRebasing == 1,
            "ERC20RebaseDistributor: not rebasing"
        );
        _exitRebase(msg.sender);
    }

    function _exitRebase(address account) internal {
        uint256 rawBalance = ERC20.balanceOf(account);
        RebasingState memory _rebasingState = rebasingState[account];
        uint256 shares = uint256(_rebasingState.nShares);
        uint256 currentRebasingSharePrice = rebasingSharePrice();
        uint256 rebasedBalance = _shares2balance(
            shares,
            currentRebasingSharePrice,
            0,
            rawBalance
        );
        uint256 mintAmount = rebasedBalance - rawBalance;

        /// @dev rounding errors could make mintAmount > unmintedRebaseRewards() because
        /// the rebasedBalance can be a larger number than the unmintedRebaseRewards(),
        /// and unmintedRebaseRewards() could be 1 wei less than the rebasedBalance,
        /// especially if there is only one user rebasing.
        /// In the next lines, when we decrement the unminted rebase rewards, there could be
        /// an underflow, so we cap the mintAmount to unmintedRebaseRewards() to avoid it.
        InterpolatedValue memory val = __unmintedRebaseRewards;
        uint256 _unmintedRebaseRewards = interpolatedValue(val);
        if (mintAmount > _unmintedRebaseRewards) {
            mintAmount = _unmintedRebaseRewards;
        }

        if (mintAmount != 0) {
            ERC20._mint(account, mintAmount);

            __unmintedRebaseRewards = InterpolatedValue({
                lastTimestamp: SafeCastLib.safeCastTo32(block.timestamp), // now
                lastValue: SafeCastLib.safeCastTo224(
                    _unmintedRebaseRewards - mintAmount
                ), // adjusted current
                targetTimestamp: val.targetTimestamp, // unchanged
                targetValue: val.targetValue -
                    SafeCastLib.safeCastTo224(mintAmount) // adjusted target
            });

            emit RebaseReward(account, block.timestamp, mintAmount);
        }

        rebasingState[account] = RebasingState({isRebasing: 0, nShares: 0});
        updateTotalRebasingShares(currentRebasingSharePrice, -int256(shares));

        emit RebaseExit(account, block.timestamp);
    }

    /// @notice distribute tokens proportionately to all rebasing accounts.
    /// @dev if no addresses are rebasing, calling this function will burn tokens
    /// from `msg.sender` and emit an event, but won't rebase up any balances.
    function distribute(uint256 amount) external {
        require(amount != 0, "ERC20RebaseDistributor: cannot distribute zero");

        // burn the tokens received
        _burn(msg.sender, amount);

        // emit event
        uint256 _rebasingSharePrice = rebasingSharePrice();
        uint256 _totalRebasingShares = totalRebasingShares;
        uint256 _rebasingSupply = _shares2balance(
            _totalRebasingShares,
            _rebasingSharePrice,
            0,
            0
        );

        // adjust up the balance of all accounts that are rebasing by increasing
        // the share price of rebasing tokens
        if (_rebasingSupply != 0) {
            // update rebasingSharePrice interpolation
            uint256 endTimestamp = block.timestamp + DISTRIBUTION_PERIOD;
            uint256 newTargetSharePrice = (amount *
                START_REBASING_SHARE_PRICE +
                __rebasingSharePrice.targetValue *
                _totalRebasingShares) / _totalRebasingShares;
            __rebasingSharePrice = InterpolatedValue({
                lastTimestamp: SafeCastLib.safeCastTo32(block.timestamp),
                lastValue: SafeCastLib.safeCastTo224(_rebasingSharePrice),
                targetTimestamp: SafeCastLib.safeCastTo32(endTimestamp),
                targetValue: SafeCastLib.safeCastTo224(newTargetSharePrice)
            });

            // update unmintedRebaseRewards interpolation
            uint256 _unmintedRebaseRewards = unmintedRebaseRewards();
            __unmintedRebaseRewards = InterpolatedValue({
                lastTimestamp: SafeCastLib.safeCastTo32(block.timestamp),
                lastValue: SafeCastLib.safeCastTo224(_unmintedRebaseRewards),
                targetTimestamp: SafeCastLib.safeCastTo32(endTimestamp),
                targetValue: __unmintedRebaseRewards.targetValue +
                    SafeCastLib.safeCastTo224(amount)
            });

            emit RebaseDistribution(
                msg.sender,
                block.timestamp,
                amount,
                _unmintedRebaseRewards,
                _rebasingSupply
            );
        } else {
            emit RebaseDistribution(
                msg.sender,
                block.timestamp,
                amount,
                0,
                _rebasingSupply
            );
        }
    }

    /// @notice True if an address subscribed to rebasing.
    function isRebasing(address account) public view returns (bool) {
        return rebasingState[account].isRebasing == 1;
    }

    /// @notice Total number of the tokens that are rebasing.
    function rebasingSupply() public view returns (uint256) {
        return _shares2balance(totalRebasingShares, rebasingSharePrice(), 0, 0);
    }

    /// @notice Total number of the tokens that are not rebasing.
    function nonRebasingSupply() external view virtual returns (uint256) {
        uint256 _totalSupply = totalSupply();
        uint256 _rebasingSupply = rebasingSupply();

        // compare rebasing supply to total supply :
        // rounding errors due to share price & number of shares could otherwise
        // make this function revert due to an underflow
        if (_rebasingSupply > _totalSupply) {
            return 0;
        } else {
            return _totalSupply - _rebasingSupply;
        }
    }

    /// @notice get the number of distributed tokens that have not yet entered
    /// circulation through rebase due to the interpolation of rewards over time.
    function pendingDistributedSupply() external view returns (uint256) {
        InterpolatedValue memory val = __unmintedRebaseRewards;
        uint256 _unmintedRebaseRewards = interpolatedValue(val);
        return __unmintedRebaseRewards.targetValue - _unmintedRebaseRewards;
    }

    /*///////////////////////////////////////////////////////////////
                            ERC20 OVERRIDE
    ///////////////////////////////////////////////////////////////*/

    /// @notice Override of balanceOf() that takes into account the unminted rebase rewards.
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        uint256 _rawBalance = ERC20.balanceOf(account);
        RebasingState memory _rebasingState = rebasingState[account];
        if (_rebasingState.isRebasing == 0) {
            return _rawBalance;
        } else {
            return
                _shares2balance(
                    _rebasingState.nShares,
                    rebasingSharePrice(),
                    0,
                    _rawBalance
                );
        }
    }

    /// @notice Total number of the tokens in existence.
    function totalSupply() public view virtual override returns (uint256) {
        return ERC20.totalSupply() + unmintedRebaseRewards();
    }

    /// @notice Target total number of the tokens in existence after interpolations
    /// of rebase rewards will have completed.
    /// @dev Equal to totalSupply() + pendingDistributedSupply().
    function targetTotalSupply() external view returns (uint256) {
        return ERC20.totalSupply() + __unmintedRebaseRewards.targetValue;
    }

    /// @notice Override of default ERC20 behavior: exit rebase before movement (if rebasing),
    /// and re-enter rebasing after movement (if rebasing).
    /// @dev for _burn(), _mint(), transfer(), and transferFrom() overrides, a naive
    /// and concise implementation would be to just _exitRebase(), call the default ERC20 behavior,
    /// and then _enterRebase(), on the 2 addresses affected by the movement, but this is highly gas
    /// inefficient and the more complex implementations below are saving up to 40% gas costs.
    function _burn(address account, uint256 amount) internal virtual override {
        // if `account` is rebasing, materialize the tokens from rebase first, to ensure
        // proper behavior in `ERC20._burn()`.
        bool isUserRebasing = rebasingState[account].isRebasing == 1;
        if (isUserRebasing) {
            _exitRebase(account);
        }

        // do ERC20._burn()
        ERC20._burn(account, amount);

        // re-enter rebasing if needed
        if (isUserRebasing) {
            _enterRebase(account);
        }
    }

    /// @notice Override of default ERC20 behavior: exit rebase before movement (if rebasing),
    /// and re-enter rebasing after movement (if rebasing).
    function _mint(address account, uint256 amount) internal virtual override {
        bool isUserRebasing = rebasingState[account].isRebasing == 1;
        if (isUserRebasing) {
            _exitRebase(account);
        }

        // do ERC20._mint()
        ERC20._mint(account, amount);

        if (isUserRebasing) {
            _enterRebase(account);
        }
    }

    /// @notice Override of default ERC20 behavior: exit rebase before movement (if rebasing),
    /// and re-enter rebasing after movement (if rebasing).
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        bool isRebasingFrom = rebasingState[msg.sender].isRebasing == 1;
        bool isRebasingTo = rebasingState[to].isRebasing == 1;
        if (isRebasingFrom) {
            _exitRebase(msg.sender);
        }
        if (isRebasingTo && to != msg.sender) {
            _exitRebase(to);
        }

        // do ERC20.transfer()
        bool success = ERC20.transfer(to, amount);

        if (isRebasingFrom) {
            _enterRebase(msg.sender);
        }
        if (isRebasingTo && to != msg.sender) {
            _enterRebase(to);
        }

        return success;
    }

    /// @notice Override of default ERC20 behavior: exit rebase before movement (if rebasing),
    /// and re-enter rebasing after movement (if rebasing).
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        bool isRebasingFrom = rebasingState[from].isRebasing == 1;
        bool isRebasingTo = rebasingState[to].isRebasing == 1;
        if (isRebasingFrom) {
            _exitRebase(from);
        }
        if (isRebasingTo && to != from) {
            _exitRebase(to);
        }

        // do ERC20.transferFrom()
        bool success = ERC20.transferFrom(from, to, amount);

        if (isRebasingFrom) {
            _enterRebase(from);
        }
        if (isRebasingTo && to != from) {
            _enterRebase(to);
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/** 
@title  An ERC20 with an embedded "Gauge" style vote with liquid weights
@author joeysantoro, eswak
@notice This contract is meant to be used to support gauge style votes with weights associated with resource allocation.
        Holders can allocate weight in any proportion to supported gauges.
        A "gauge" is represented by an address which would receive the resources periodically or continuously.
        For example, gauges can be used to direct token emissions, similar to Curve or Tokemak.
        Alternatively, gauges can be used to direct another quantity such as relative access to a line of credit.
        This contract is abstract, and a parent shall implement public setter with adequate access control to manage
        the gauge set and caps.
        All gauges are in the set `_gauges` (live + deprecated).  
        Users can only add weight to live gauges but can remove weight from live or deprecated gauges.
        Gauges can be deprecated and reinstated, and will maintain any non-removed weight from before.
@dev    SECURITY NOTES: `maxGauges` is a critical variable to protect against gas DOS attacks upon token transfer. 
        This must be low enough to allow complicated transactions to fit in a block.
        Weight state is preserved on the gauge and user level even when a gauge is removed, in case it is re-added. 
        This maintains state efficiently, and global accounting is managed only on the `_totalWeight`
@dev This contract was originally published as part of TribeDAO's flywheel-v2 repo, please see:
    https://github.com/fei-protocol/flywheel-v2/blob/main/src/token/ERC20Gauges.sol
    The original version was included in 2 audits :
    - https://code4rena.com/reports/2022-04-xtribe/
    - https://consensys.net/diligence/audits/2022/04/tribe-dao-flywheel-v2-xtribe-xerc4626/
    ECG made the following changes to the original flywheel-v2 version :
    - Does not inherit Solmate's Auth (all requiresAuth functions are now internal, see below)
        -> This contract is abstract, and permissioned public functions can be added in parent.
        -> permissioned public functions to add in parent:
            - function addGauge(address) external returns (uint112)
            - function removeGauge(address) external
            - function setMaxGauges(uint256) external
            - function setCanExceedMaxGauges(address, bool) external
    - Remove public addGauge(address) requiresAuth method 
    - Remove public removeGauge(address) requiresAuth method
    - Remove public replaceGauge(address, address) requiresAuth method
    - Remove public setMaxGauges(uint256) requiresAuth method
        ... Add internal _setMaxGauges(uint256) method
    - Remove public setContractExceedMaxGauges(address, bool) requiresAuth method
        ... Add internal _setCanExceedMaxGauges(address, bool) method
    - Remove `calculateGaugeAllocation` helper function
    - Add `isDeprecatedGauge(address)->bool` view function that returns true if gauge is deprecated.
    - Consistency: make incrementGauges return a uint112 instead of uint256
    - Import OpenZeppelin ERC20 & EnumerableSet instead of Solmate's
    - Update error management style (use require + messages instead of Solidity errors)
    - Implement C4 audit fixes for [M-03], [M-04], [M-07], [G-02], and [G-04].
    - Remove cycle-based logic
    - Add gauge types
    - Prevent removal of gauges if they were not previously added
    - Add liveGauges() and numLiveGauges() getters
*/
abstract contract ERC20Gauges is ERC20 {
    using EnumerableSet for EnumerableSet.AddressSet;

    /*///////////////////////////////////////////////////////////////
                        GAUGE STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice a mapping from users to gauges to a user's allocated weight to that gauge
    mapping(address => mapping(address => uint256)) public getUserGaugeWeight;

    /// @notice a mapping from a user to their total allocated weight across all gauges
    /// @dev NOTE this may contain weights for deprecated gauges
    mapping(address => uint256) public getUserWeight;

    /// @notice a mapping from a gauge to the total weight allocated to it
    /// @dev NOTE this may contain weights for deprecated gauges
    mapping(address => uint256) public getGaugeWeight;

    /// @notice the total global allocated weight ONLY of live gauges
    uint256 public totalWeight;

    /// @notice the total allocated weight to gauges of a given type, ONLY of live gauges.
    /// keys : totalTypeWeight[type] = total.
    mapping(uint256 => uint256) public totalTypeWeight;

    /// @notice the type of gauges.
    mapping(address => uint256) public gaugeType;

    mapping(address => EnumerableSet.AddressSet) internal _userGauges;

    EnumerableSet.AddressSet internal _gauges;

    // Store deprecated gauges in case a user needs to free dead weight
    EnumerableSet.AddressSet internal _deprecatedGauges;

    /*///////////////////////////////////////////////////////////////
                            VIEW HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice returns the set of live + deprecated gauges
    function gauges() external view returns (address[] memory) {
        return _gauges.values();
    }

    /// @notice returns true if `gauge` is not in deprecated gauges
    function isGauge(address gauge) public view returns (bool) {
        return _gauges.contains(gauge) && !_deprecatedGauges.contains(gauge);
    }

    /// @notice returns true if `gauge` is in deprecated gauges
    function isDeprecatedGauge(address gauge) public view returns (bool) {
        return _deprecatedGauges.contains(gauge);
    }

    /// @notice returns the number of live + deprecated gauges
    function numGauges() external view returns (uint256) {
        return _gauges.length();
    }

    /// @notice returns the set of previously live but now deprecated gauges
    function deprecatedGauges() external view returns (address[] memory) {
        return _deprecatedGauges.values();
    }

    /// @notice returns the number of deprecated gauges
    function numDeprecatedGauges() external view returns (uint256) {
        return _deprecatedGauges.length();
    }

    /// @notice returns the set of currently live gauges
    function liveGauges() external view returns (address[] memory _liveGauges) {
        _liveGauges = new address[](
            _gauges.length() - _deprecatedGauges.length()
        );
        address[] memory allGauges = _gauges.values();
        uint256 j;
        for (uint256 i; i < allGauges.length && j < _liveGauges.length; ) {
            if (!_deprecatedGauges.contains(allGauges[i])) {
                _liveGauges[j] = allGauges[i];
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        return _liveGauges;
    }

    /// @notice returns the number of currently live gauges
    function numLiveGauges() external view returns (uint256) {
        return _gauges.length() - _deprecatedGauges.length();
    }

    /// @notice returns the set of gauges the user has allocated to, may be live or deprecated.
    function userGauges(address user) external view returns (address[] memory) {
        return _userGauges[user].values();
    }

    /// @notice returns true if `gauge` is in user gauges
    function isUserGauge(
        address user,
        address gauge
    ) external view returns (bool) {
        return _userGauges[user].contains(gauge);
    }

    /// @notice returns the number of user gauges
    function numUserGauges(address user) external view returns (uint256) {
        return _userGauges[user].length();
    }

    /// @notice helper function exposing the amount of weight available to allocate for a user
    function userUnusedWeight(address user) external view returns (uint256) {
        return balanceOf(user) - getUserWeight[user];
    }

    /*///////////////////////////////////////////////////////////////
                        USER GAUGE OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when incrementing a gauge
    event IncrementGaugeWeight(
        address indexed user,
        address indexed gauge,
        uint256 weight
    );

    /// @notice emitted when decrementing a gauge
    event DecrementGaugeWeight(
        address indexed user,
        address indexed gauge,
        uint256 weight
    );

    /** 
    @notice increment a gauge with some weight for the caller
    @param gauge the gauge to increment
    @param weight the amount of weight to increment on gauge
    @return newUserWeight the new user weight
    */
    function incrementGauge(
        address gauge,
        uint256 weight
    ) public virtual returns (uint256 newUserWeight) {
        require(isGauge(gauge), "ERC20Gauges: invalid gauge");
        _incrementGaugeWeight(msg.sender, gauge, weight);
        return _incrementUserAndGlobalWeights(msg.sender, weight);
    }

    /// @dev this function does not check if the gauge exists, this is performed
    /// in the calling function.
    function _incrementGaugeWeight(
        address user,
        address gauge,
        uint256 weight
    ) internal virtual {
        bool added = _userGauges[user].add(gauge); // idempotent add
        if (added && _userGauges[user].length() > maxGauges) {
            require(canExceedMaxGauges[user], "ERC20Gauges: exceed max gauges");
        }

        getUserGaugeWeight[user][gauge] += weight;

        getGaugeWeight[gauge] += weight;

        totalTypeWeight[gaugeType[gauge]] += weight;

        emit IncrementGaugeWeight(user, gauge, weight);
    }

    function _incrementUserAndGlobalWeights(
        address user,
        uint256 weight
    ) internal returns (uint256 newUserWeight) {
        newUserWeight = getUserWeight[user] + weight;
        // Ensure under weight
        require(newUserWeight <= balanceOf(user), "ERC20Gauges: overweight");

        // Update gauge state
        getUserWeight[user] = newUserWeight;

        totalWeight += weight;
    }

    /** 
    @notice increment a list of gauges with some weights for the caller
    @param gaugeList the gauges to increment
    @param weights the weights to increment by
    @return newUserWeight the new user weight
    */
    function incrementGauges(
        address[] calldata gaugeList,
        uint256[] calldata weights
    ) public virtual returns (uint256 newUserWeight) {
        uint256 size = gaugeList.length;
        require(weights.length == size, "ERC20Gauges: size mismatch");

        // store total in summary for batch update on user/global state
        uint256 weightsSum;

        // Update gauge specific state
        for (uint256 i = 0; i < size; ) {
            address gauge = gaugeList[i];
            uint256 weight = weights[i];
            weightsSum += weight;

            require(isGauge(gauge), "ERC20Gauges: invalid gauge");

            _incrementGaugeWeight(msg.sender, gauge, weight);
            unchecked {
                ++i;
            }
        }
        return _incrementUserAndGlobalWeights(msg.sender, weightsSum);
    }

    /** 
     @notice decrement a gauge with some weight for the caller
     @param gauge the gauge to decrement
     @param weight the amount of weight to decrement on gauge
     @return newUserWeight the new user weight
    */
    function decrementGauge(
        address gauge,
        uint256 weight
    ) public virtual returns (uint256 newUserWeight) {
        // All operations will revert on underflow, protecting against bad inputs
        _decrementGaugeWeight(msg.sender, gauge, weight);
        if (!_deprecatedGauges.contains(gauge)) {
            totalTypeWeight[gaugeType[gauge]] -= weight;
            totalWeight -= weight;
        }
        return getUserWeight[msg.sender];
    }

    function _decrementGaugeWeight(
        address user,
        address gauge,
        uint256 weight
    ) internal virtual {
        uint256 oldWeight = getUserGaugeWeight[user][gauge];

        getUserGaugeWeight[user][gauge] = oldWeight - weight;
        if (oldWeight == weight) {
            // If removing all weight, remove gauge from user list.
            require(_userGauges[user].remove(gauge));
        }

        getGaugeWeight[gauge] -= weight;

        getUserWeight[user] -= weight;

        emit DecrementGaugeWeight(user, gauge, weight);
    }

    /** 
     @notice decrement a list of gauges with some weights for the caller
     @param gaugeList the gauges to decrement
     @param weights the list of weights to decrement on the gauges
     @return newUserWeight the new user weight
    */
    function decrementGauges(
        address[] calldata gaugeList,
        uint256[] calldata weights
    ) public virtual returns (uint256 newUserWeight) {
        uint256 size = gaugeList.length;
        require(weights.length == size, "ERC20Gauges: size mismatch");

        // store total in summary for batch update on user/global state
        uint256 weightsSum;

        // Update gauge specific state
        // All operations will revert on underflow, protecting against bad inputs
        for (uint256 i = 0; i < size; ) {
            address gauge = gaugeList[i];
            uint256 weight = weights[i];

            _decrementGaugeWeight(msg.sender, gauge, weight);
            if (!_deprecatedGauges.contains(gauge)) {
                totalTypeWeight[gaugeType[gauge]] -= weight;
                weightsSum += weight;
            }
            unchecked {
                ++i;
            }
        }
        totalWeight -= weightsSum;
        return getUserWeight[msg.sender];
    }

    /*///////////////////////////////////////////////////////////////
                        ADMIN GAUGE OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when adding a new gauge to the live set.
    event AddGauge(address indexed gauge, uint256 indexed gaugeType);

    /// @notice emitted when removing a gauge from the live set.
    event RemoveGauge(address indexed gauge);

    /// @notice emitted when updating the max number of gauges a user can delegate to.
    event MaxGaugesUpdate(uint256 oldMaxGauges, uint256 newMaxGauges);

    /// @notice emitted when changing a contract's approval to go over the max gauges.
    event CanExceedMaxGaugesUpdate(
        address indexed account,
        bool canExceedMaxGauges
    );

    /// @notice the default maximum amount of gauges a user can allocate to.
    /// @dev if this number is ever lowered, or a contract has an override, then existing addresses MAY have more gauges allocated to. Use `numUserGauges` to check this.
    uint256 public maxGauges;

    /// @notice an approve list for contracts to go above the max gauge limit.
    mapping(address => bool) public canExceedMaxGauges;

    function _addGauge(
        uint256 _type,
        address gauge
    ) internal returns (uint256 weight) {
        bool newAdd = _gauges.add(gauge);
        bool previouslyDeprecated = _deprecatedGauges.remove(gauge);
        // add and fail loud if zero address or already present and not deprecated
        require(
            gauge != address(0) && (newAdd || previouslyDeprecated),
            "ERC20Gauges: invalid gauge"
        );

        if (newAdd) {
            // save gauge type on first add
            gaugeType[gauge] = _type;
        } else {
            // cannot change gauge type on re-add of a previously deprecated gauge
            require(gaugeType[gauge] == _type, "ERC20Gauges: invalid type");
        }

        // Check if some previous weight exists and re-add to total. Gauge and user weights are preserved.
        weight = getGaugeWeight[gauge];
        if (weight != 0) {
            totalTypeWeight[_type] += weight;
            totalWeight += weight;
        }

        emit AddGauge(gauge, _type);
    }

    function _removeGauge(address gauge) internal {
        // add to deprecated and fail loud if not present
        require(
            _gauges.contains(gauge) && _deprecatedGauges.add(gauge),
            "ERC20Gauges: invalid gauge"
        );

        // Remove weight from total but keep the gauge and user weights in storage in case gauge is re-added.
        uint256 weight = getGaugeWeight[gauge];
        if (weight != 0) {
            totalTypeWeight[gaugeType[gauge]] -= weight;
            totalWeight -= weight;
        }

        emit RemoveGauge(gauge);
    }

    /// @notice set the new max gauges. Requires auth by `authority`.
    /// @dev if this is set to a lower number than the current max, users MAY have more gauges active than the max. Use `numUserGauges` to check this.
    function _setMaxGauges(uint256 newMax) internal {
        uint256 oldMax = maxGauges;
        maxGauges = newMax;

        emit MaxGaugesUpdate(oldMax, newMax);
    }

    /// @notice set the canExceedMaxGauges flag for an account.
    function _setCanExceedMaxGauges(
        address account,
        bool canExceedMax
    ) internal {
        if (canExceedMax) {
            require(
                account.code.length != 0,
                "ERC20Gauges: not a smart contract"
            );
        }

        canExceedMaxGauges[account] = canExceedMax;

        emit CanExceedMaxGaugesUpdate(account, canExceedMax);
    }

    /*///////////////////////////////////////////////////////////////
                            ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// NOTE: any "removal" of tokens from a user requires userUnusedWeight < amount.
    /// _decrementWeightUntilFree is called as a greedy algorithm to free up weight.
    /// It may be more gas efficient to free weight before burning or transferring tokens.

    function _burn(address from, uint256 amount) internal virtual override {
        _decrementWeightUntilFree(from, amount);
        super._burn(from, amount);
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _decrementWeightUntilFree(msg.sender, amount);
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _decrementWeightUntilFree(from, amount);
        return super.transferFrom(from, to, amount);
    }

    /// a greedy algorithm for freeing weight before a token burn/transfer
    /// frees up entire gauges, so likely will free more than `weight`
    function _decrementWeightUntilFree(address user, uint256 weight) internal {
        uint256 userFreeWeight = balanceOf(user) - getUserWeight[user];

        // early return if already free
        if (userFreeWeight >= weight) return;

        // cache totals for batch updates
        uint256 userFreed;
        uint256 totalFreed;

        // Loop through all user gauges, live and deprecated
        address[] memory gaugeList = _userGauges[user].values();

        // Free gauges until through entire list or under weight
        uint256 size = gaugeList.length;
        for (
            uint256 i = 0;
            i < size && (userFreeWeight + userFreed) < weight;

        ) {
            address gauge = gaugeList[i];
            uint256 userGaugeWeight = getUserGaugeWeight[user][gauge];
            if (userGaugeWeight != 0) {
                userFreed += userGaugeWeight;
                _decrementGaugeWeight(user, gauge, userGaugeWeight);

                // If the gauge is live (not deprecated), include its weight in the total to remove
                if (!_deprecatedGauges.contains(gauge)) {
                    totalTypeWeight[gaugeType[gauge]] -= userGaugeWeight;
                    totalFreed += userGaugeWeight;
                }
            }
            unchecked {
                ++i;
            }
        }

        totalWeight -= totalFreed;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCastLib} from "@solmate/src/utils/SafeCastLib.sol";

import {CoreRef} from "@src/core/CoreRef.sol";
import {CoreRoles} from "@src/core/CoreRoles.sol";
import {IRateLimitedV2} from "@src/rate-limits/IRateLimitedV2.sol";

/// @title abstract contract for putting a rate limit on how fast a contract
/// can perform an action e.g. Minting
/// @author Elliot Friedman
abstract contract RateLimitedV2 is IRateLimitedV2, CoreRef {
    using SafeCastLib for *;

    /// @notice maximum rate limit per second governance can set for this contract
    uint256 public immutable MAX_RATE_LIMIT_PER_SECOND;

    /// ------------- First Storage Slot -------------

    /// @notice the rate per second for this contract
    uint128 public rateLimitPerSecond;

    /// @notice the cap of the buffer that can be used at once
    uint128 public bufferCap;

    /// ------------- Second Storage Slot -------------

    /// @notice the last time the buffer was used by the contract
    uint32 public lastBufferUsedTime;

    /// @notice the buffer at the timestamp of lastBufferUsedTime
    uint224 public bufferStored;

    /// @notice RateLimitedV2 constructor
    /// @param _maxRateLimitPerSecond maximum rate limit per second that governance can set
    /// @param _rateLimitPerSecond starting rate limit per second
    /// @param _bufferCap cap on buffer size for this rate limited instance
    constructor(
        uint256 _maxRateLimitPerSecond,
        uint128 _rateLimitPerSecond,
        uint128 _bufferCap
    ) {
        lastBufferUsedTime = block.timestamp.safeCastTo32();

        _setBufferCap(_bufferCap);
        bufferStored = _bufferCap;

        require(
            _rateLimitPerSecond <= _maxRateLimitPerSecond,
            "RateLimited: rateLimitPerSecond too high"
        );
        _setRateLimitPerSecond(_rateLimitPerSecond);

        MAX_RATE_LIMIT_PER_SECOND = _maxRateLimitPerSecond;
    }

    /// @notice set the rate limit per second
    /// @param newRateLimitPerSecond the new rate limit per second of the contract
    function setRateLimitPerSecond(
        uint128 newRateLimitPerSecond
    ) external virtual onlyCoreRole(CoreRoles.GOVERNOR) {
        require(
            newRateLimitPerSecond <= MAX_RATE_LIMIT_PER_SECOND,
            "RateLimited: rateLimitPerSecond too high"
        );
        _updateBufferStored(bufferCap);

        _setRateLimitPerSecond(newRateLimitPerSecond);
    }

    /// @notice set the buffer cap
    /// @param newBufferCap new buffer cap to set
    function setBufferCap(
        uint128 newBufferCap
    ) external virtual onlyCoreRole(CoreRoles.GOVERNOR) {
        _setBufferCap(newBufferCap);
    }

    /// @notice the amount of action used before hitting limit
    /// @dev replenishes at rateLimitPerSecond per second up to bufferCap
    function buffer() public view returns (uint256) {
        uint256 elapsed = block.timestamp.safeCastTo32() - lastBufferUsedTime;
        return
            Math.min(bufferStored + (rateLimitPerSecond * elapsed), bufferCap);
    }

    /// @notice the method that enforces the rate limit.
    /// Decreases buffer by "amount".
    /// If buffer is <= amount, revert
    /// @param amount to decrease buffer by
    function _depleteBuffer(uint256 amount) internal {
        uint256 newBuffer = buffer();

        require(newBuffer != 0, "RateLimited: no rate limit buffer");
        require(amount <= newBuffer, "RateLimited: rate limit hit");

        uint32 blockTimestamp = block.timestamp.safeCastTo32();
        uint224 newBufferStored = (newBuffer - amount).safeCastTo224();

        /// gas optimization to only use a single SSTORE
        lastBufferUsedTime = blockTimestamp;
        bufferStored = newBufferStored;

        emit BufferUsed(amount, bufferStored);
    }

    /// @notice function to replenish buffer
    /// @param amount to increase buffer by if under buffer cap
    function _replenishBuffer(uint256 amount) internal {
        uint256 newBuffer = buffer();

        uint256 _bufferCap = bufferCap; /// gas opti, save an SLOAD

        /// cannot replenish any further if already at buffer cap
        if (newBuffer == _bufferCap) {
            /// save an SSTORE + some stack operations if buffer cannot be increased.
            /// last buffer used time doesn't need to be updated as buffer cannot
            /// increase past the buffer cap
            return;
        }

        uint32 blockTimestamp = block.timestamp.safeCastTo32();
        /// ensure that bufferStored cannot be gt buffer cap
        uint224 newBufferStored = Math
            .min(newBuffer + amount, _bufferCap)
            .safeCastTo224();

        /// gas optimization to only use a single SSTORE
        lastBufferUsedTime = blockTimestamp;
        bufferStored = newBufferStored;

        emit BufferReplenished(amount, bufferStored);
    }

    /// @param newRateLimitPerSecond the new rate limit per second of the contract
    function _setRateLimitPerSecond(uint128 newRateLimitPerSecond) internal {
        uint256 oldRateLimitPerSecond = rateLimitPerSecond;
        rateLimitPerSecond = newRateLimitPerSecond;

        emit RateLimitPerSecondUpdate(
            oldRateLimitPerSecond,
            newRateLimitPerSecond
        );
    }

    /// @param newBufferCap new buffer cap to set
    function _setBufferCap(uint128 newBufferCap) internal {
        _updateBufferStored(newBufferCap);

        uint256 oldBufferCap = bufferCap;
        bufferCap = newBufferCap;

        emit BufferCapUpdate(oldBufferCap, newBufferCap);
    }

    function _updateBufferStored(uint128 newBufferCap) internal {
        uint224 newBufferStored = buffer().safeCastTo224();
        uint32 newBlockTimestamp = block.timestamp.safeCastTo32();

        if (newBufferStored > newBufferCap) {
            bufferStored = uint224(newBufferCap); /// safe upcast as no precision can be lost when going from 128 -> 224
            lastBufferUsedTime = newBlockTimestamp;
        } else {
            bufferStored = newBufferStored;
            lastBufferUsedTime = newBlockTimestamp;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

import "./ECDSA.sol";
import "../ShortStrings.sol";
import "../../interfaces/IERC5267.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo240(uint256 x) internal pure returns (uint240 y) {
        require(x < 1 << 240);

        y = uint240(x);
    }

    function safeCastTo232(uint256 x) internal pure returns (uint232 y) {
        require(x < 1 << 232);

        y = uint232(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo216(uint256 x) internal pure returns (uint216 y) {
        require(x < 1 << 216);

        y = uint216(x);
    }

    function safeCastTo208(uint256 x) internal pure returns (uint208 y) {
        require(x < 1 << 208);

        y = uint208(x);
    }

    function safeCastTo200(uint256 x) internal pure returns (uint200 y) {
        require(x < 1 << 200);

        y = uint200(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo184(uint256 x) internal pure returns (uint184 y) {
        require(x < 1 << 184);

        y = uint184(x);
    }

    function safeCastTo176(uint256 x) internal pure returns (uint176 y) {
        require(x < 1 << 176);

        y = uint176(x);
    }

    function safeCastTo168(uint256 x) internal pure returns (uint168 y) {
        require(x < 1 << 168);

        y = uint168(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo152(uint256 x) internal pure returns (uint152 y) {
        require(x < 1 << 152);

        y = uint152(x);
    }

    function safeCastTo144(uint256 x) internal pure returns (uint144 y) {
        require(x < 1 << 144);

        y = uint144(x);
    }

    function safeCastTo136(uint256 x) internal pure returns (uint136 y) {
        require(x < 1 << 136);

        y = uint136(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo120(uint256 x) internal pure returns (uint120 y) {
        require(x < 1 << 120);

        y = uint120(x);
    }

    function safeCastTo112(uint256 x) internal pure returns (uint112 y) {
        require(x < 1 << 112);

        y = uint112(x);
    }

    function safeCastTo104(uint256 x) internal pure returns (uint104 y) {
        require(x < 1 << 104);

        y = uint104(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo88(uint256 x) internal pure returns (uint88 y) {
        require(x < 1 << 88);

        y = uint88(x);
    }

    function safeCastTo80(uint256 x) internal pure returns (uint80 y) {
        require(x < 1 << 80);

        y = uint80(x);
    }

    function safeCastTo72(uint256 x) internal pure returns (uint72 y) {
        require(x < 1 << 72);

        y = uint72(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo56(uint256 x) internal pure returns (uint56 y) {
        require(x < 1 << 56);

        y = uint56(x);
    }

    function safeCastTo48(uint256 x) internal pure returns (uint48 y) {
        require(x < 1 << 48);

        y = uint48(x);
    }

    function safeCastTo40(uint256 x) internal pure returns (uint40 y) {
        require(x < 1 << 40);

        y = uint40(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

/// @title abstract contract for putting a rate limit on how fast a contract
/// can perform an action e.g. Minting
/// @author Elliot Friedman
interface IRateLimitedV2 {
    /// ------------- View Only API's -------------

    /// @notice maximum rate limit per second governance can set for this contract
    function MAX_RATE_LIMIT_PER_SECOND() external view returns (uint256);

    /// @notice the rate per second for this contract
    function rateLimitPerSecond() external view returns (uint128);

    /// @notice the cap of the buffer that can be used at once
    function bufferCap() external view returns (uint128);

    /// @notice the last time the buffer was used by the contract
    function lastBufferUsedTime() external view returns (uint32);

    /// @notice the buffer at the timestamp of lastBufferUsedTime
    function bufferStored() external view returns (uint224);

    /// @notice the amount of action used before hitting limit
    /// @dev replenishes at rateLimitPerSecond per second up to bufferCap
    function buffer() external view returns (uint256);

    /// ------------- Governor Only API's -------------

    /// @notice set the rate limit per second
    function setRateLimitPerSecond(uint128 newRateLimitPerSecond) external;

    /// @notice set the buffer cap
    function setBufferCap(uint128 newBufferCap) external;

    /// ------------- Events -------------

    /// @notice event emitted when buffer gets eaten into
    event BufferUsed(uint256 amountUsed, uint256 bufferRemaining);

    /// @notice event emitted when buffer gets replenished
    event BufferReplenished(uint256 amountReplenished, uint256 bufferRemaining);

    /// @notice event emitted when buffer cap is updated
    event BufferCapUpdate(uint256 oldBufferCap, uint256 newBufferCap);

    /// @notice event emitted when rate limit per second is updated
    event RateLimitPerSecondUpdate(
        uint256 oldRateLimitPerSecond,
        uint256 newRateLimitPerSecond
    );
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/ShortStrings.sol)

pragma solidity ^0.8.8;

import "./StorageSlot.sol";

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant _FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.0;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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