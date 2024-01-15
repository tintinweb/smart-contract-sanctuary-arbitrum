// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ERC20Burnable} from "openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import {ICreditAccount} from "./ICreditAccount.sol";
import {CreditAccountAccessControl} from "./utils/CreditAccountAccessControl.sol";
import {RevenueEscrow} from "./utils/RevenueEscrow.sol";
import {Math} from "openzeppelin/utils/math/Math.sol";
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {Pausable} from "openzeppelin/security/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";

contract CreditAccount is
    ICreditAccount,
    Ownable2Step,
    ERC20Burnable,
    CreditAccountAccessControl,
    RevenueEscrow,
    Pausable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    /// @notice Parameters to initialize the credit account
    struct ConstructorParams {
        /// @notice The address of the borrower
        address borrower;
        /// @notice The terms of the credit account
        ICreditAccount.Terms terms;
        /// @notice The token name of the credit account
        string name;
        /// @notice The token symbol of the credit account
        string symbol;
        /// @notice The list of blacklisted functions when the
        /// account is closed
        bytes4[] blacklistedWhenClosedFns;
    }

    /// @notice The address of the borrower
    address internal immutable i_borrower;
    /// @notice The terms of the credit acount
    ICreditAccount.Terms internal s_terms;
    /// @notice The credit account loan's maturity date
    uint256 internal s_maturityDate;
    /// @notice The amount of principal funded by the lenders
    uint256 internal s_fundedPrincipalAmount;
    /// @notice The amount deposited by the borrowers
    uint256 internal s_borrowerDepositedAmount;
    /// @notice The amount the lender's have withdrawn
    /// after the credit account is closed
    uint256 internal s_lenderAfterClosedWithdrawnAmount;
    /// @notice The current status of the credit account
    ICreditAccount.Status internal s_status;

    constructor(ConstructorParams memory params)
        Ownable2Step()
        ERC20(params.name, params.symbol)
        CreditAccountAccessControl(params.blacklistedWhenClosedFns)
    {
        if (params.terms.tenor == 0) revert InvalidTenor();
        if (params.terms.principalAmount == 0) revert InvalidPrincipalAmount();
        if (params.terms.interestAmount == 0) revert InvalidInterestAmount();

        i_borrower = params.borrower;
        s_terms = params.terms;
        s_status = ICreditAccount.Status.CREATED;
    }

    //################//
    //    Pausable    //
    //################//

    /// @inheritdoc ICreditAccount
    function emergencyPause() external onlyOwner {
        _pause();
    }

    /// @inheritdoc ICreditAccount
    function emergencyUnpause() external onlyOwner {
        _unpause();
    }

    //################//
    //     Loans      //
    //################//

    /// @inheritdoc ICreditAccount
    function getTerms() external view override returns (Terms memory) {
        return s_terms;
    }

    /// @inheritdoc ICreditAccount
    function getMaturityDate() external view override returns (uint256) {
        return s_maturityDate;
    }

    /// @inheritdoc ICreditAccount
    function getStatus() external view override returns (ICreditAccount.Status) {
        return s_status;
    }

    /// @inheritdoc ICreditAccount
    function open() external onlyStakeholder whenNotPaused whenInStatus(ICreditAccount.Status.CREATED) {
        uint256 fundedPrincipalAmount = s_fundedPrincipalAmount;
        if (!_hasFundedPrincipal()) {
            revert InsufficientPrincipal(s_terms.principalAmount, fundedPrincipalAmount);
        }
        if (!_isLoanCollateralized()) revert LoanNotCollateralized();
        s_status = ICreditAccount.Status.ACTIVE;
        uint256 maturityDate = block.timestamp + s_terms.tenor;
        s_maturityDate = maturityDate;
        emit CreditAccountOpened(maturityDate);
    }

    /// @inheritdoc ICreditAccount
    function close() external onlyStakeholder whenInStatus(ICreditAccount.Status.ACTIVE) whenNotPaused {
        if (block.timestamp < s_maturityDate) revert LoanNotMatured(s_maturityDate);
        s_status = ICreditAccount.Status.CLOSED;
        emit CreditAccountClosed();
    }

    /// @inheritdoc ICreditAccount
    function emergencyClose() external onlyOwner whenPaused {
        s_status = ICreditAccount.Status.EMERGENCY_CLOSED;
        emit CreditAccountEmergencyClosed();
    }

    /// @inheritdoc ICreditAccount
    function deposit(uint256 amount)
        external
        payable
        override
        whenNotPaused
        whenInStatus(ICreditAccount.Status.CREATED)
    {
        bool isETHDenominated = _isETHDenominated();
        if (isETHDenominated) {
            amount = msg.value;
        }

        if (amount == 0) {
            revert InvalidDepositAmount();
        }

        if (msg.sender == i_borrower) {
            s_borrowerDepositedAmount += amount;
        } else {
            s_fundedPrincipalAmount += amount;
            _mint(msg.sender, amount);
        }

        if (!isETHDenominated) {
            IERC20 token = IERC20(s_terms.token);
            token.safeTransferFrom(msg.sender, address(this), amount);
        }

        emit CreditAccountDeposited(msg.sender, amount);
    }

    /// @inheritdoc ICreditAccount
    function withdraw(uint256 amount) external override whenNotInStatus(ICreditAccount.Status.ACTIVE) {
        if (amount == 0) revert ICreditAccount.InvalidWithdrawableAmount();
        uint256 withdrawableAmount = msg.sender == i_borrower ? _withdrawBorrower(amount) : _withdrawLender(amount);
        _transferFromAccount(msg.sender, withdrawableAmount);
        emit CreditAccountWithdrawn(msg.sender, withdrawableAmount);
    }

    /// @inheritdoc ICreditAccount
    function getTotalLenderWithdrawableAmount() external view returns (uint256) {
        return _getTotalLenderWithdrawableAmount();
    }

    /// @inheritdoc ICreditAccount
    function getBorrowerWithdrawableAmount() external view returns (uint256) {
        return _getBorrowerWithdrawableAmount();
    }

    /// @inheritdoc ICreditAccount
    function getWithdrawableAmount(address withdrawer) external view returns (uint256) {
        if (withdrawer == i_borrower) return _getBorrowerWithdrawableAmount();
        uint256 share = balanceOf(withdrawer);
        return share * _getTotalLenderWithdrawableAmount() / totalSupply();
    }

    /// @inheritdoc ICreditAccount
    function getTotalFundedPrincipalAmount() external view returns (uint256) {
        return s_fundedPrincipalAmount;
    }

    /// @inheritdoc ICreditAccount
    function getBorrowerFundedAmount() external view returns (uint256) {
        return s_borrowerDepositedAmount;
    }

    //###############################//
    // Credit Account Access Control //
    //###############################//

    /// @inheritdoc ICreditAccount
    function toggleWhitelist(CreditAccountAccessControl.Action[] calldata actions) external override onlyOwner {
        _toggleWhitelist(actions);
    }

    /// @inheritdoc ICreditAccount
    function execute(CreditAccountAccessControl.ExecuteAction[] calldata executeActions)
        external
        override
        nonReentrant
    {
        _execute(executeActions, msg.sender == owner(), s_status == ICreditAccount.Status.CLOSED || paused());
    }

    /// @inheritdoc ICreditAccount
    function isWhitelisted(address target, address caller, bytes4 fnSelector) external view override returns (bool) {
        return _isWhitelisted(target, caller, fnSelector);
    }

    /// @inheritdoc ICreditAccount
    function toggleBlacklistedWhenClosedActions(
        CreditAccountAccessControl.BlacklistedOnClosedAction[] calldata blacklistedActions
    ) external override onlyOwner {
        _setBlacklistedWhenClosedActions(blacklistedActions);
    }

    /// @inheritdoc ICreditAccount
    function isBlacklistedWhenClosed(bytes4 fn) external view override returns (bool) {
        return _isBlacklistedWhenClosed(fn);
    }

    // ################# //
    //  Revenue Escrow   //
    // ################# //

    /// @inheritdoc ICreditAccount
    function addEscrowedContracts(RevenueEscrow.EscrowedContractParams[] calldata escrowedContracts)
        external
        override
        onlyOwner
        whenInStatus(ICreditAccount.Status.CREATED)
    {
        _addEscrowedContracts(escrowedContracts);
    }

    /// @inheritdoc ICreditAccount
    function removeEscrowedContracts(address[] calldata escrowedContracts)
        external
        override
        onlyOwner
        whenInStatus(ICreditAccount.Status.CREATED)
    {
        _removeEscrowedContracts(escrowedContracts);
    }

    /// @inheritdoc ICreditAccount
    function escrowContract(address target) external override onlyOwner {
        _escrowContract(target);
    }

    /// @inheritdoc ICreditAccount
    function releaseEscrow(address[] calldata targets)
        external
        override
        onlyOwner
        whenNotInStatus(ICreditAccount.Status.ACTIVE)
    {
        _releaseFromEscrow(targets, i_borrower);
    }

    /// @inheritdoc ICreditAccount
    function isFullyEscrowed() external view override returns (bool) {
        return _isFullyEscrowed();
    }

    /// @inheritdoc ICreditAccount
    function isPendingEscrow(address target) external view override returns (bool) {
        return s_revenueEscrow.escrowedContracts[target].transferOwnershipFn != bytes4("")
            && s_revenueEscrow.escrowedContracts[target].getOwnerFn != bytes4("");
    }

    /// @inheritdoc ICreditAccount
    function isEscrowed(address target) external view override returns (bool) {
        return s_revenueEscrow.escrowedContracts[target].isEscrowed;
    }

    /// @inheritdoc ICreditAccount
    function getRevenueEscrowState() external view override returns (uint256, uint256) {
        return (s_revenueEscrow.numEscrowedContracts, s_revenueEscrow.pendingEscrowedContracts);
    }

    //################//
    //     Helpers    //
    //################//

    /// @notice Returns whether or not the credit account's loan
    /// is protected
    /// @return True if the credit account has fully escrowed
    /// the borrower's protocol or the borrower has deposited
    /// sufficient principal
    function _isLoanCollateralized() internal view returns (bool) {
        return _isLoanCoveredByBorrowerDeposit()
            || (_isFullyEscrowed() && s_borrowerDepositedAmount >= s_terms.securityDepositAmount);
    }

    /// @notice Returns whether or not the amount that the borrower
    /// has deposited is greater than or equal to the interest amount
    /// and the security deposit amount
    /// @return True if the borrower has deposited an amount greater
    /// than the sum of the interest and security deposit amounts
    function _isLoanCoveredByBorrowerDeposit() internal view returns (bool) {
        return s_borrowerDepositedAmount >= s_terms.interestAmount + s_terms.securityDepositAmount;
    }

    /// @notice Returns whether or not the credit account is denominated
    /// in ETH
    /// @return True if the credit account is denominated in ETH
    function _isETHDenominated() internal view returns (bool) {
        return s_terms.token == address(0);
    }

    /// @notice Returns whether or not the lenders have
    /// funded the credit account with sufficient principal
    /// @return True if the lender has funded the credit account
    /// with sufficient principal
    function _hasFundedPrincipal() internal view returns (bool) {
        return s_fundedPrincipalAmount >= s_terms.principalAmount;
    }

    /// @notice Returns the balance of the credit account
    /// @return The balance of the credit account
    function _getCreditAccountBalance() internal view returns (uint256) {
        uint256 currentBalanceAmount =
            _isETHDenominated() ? address(this).balance : IERC20(s_terms.token).balanceOf(address(this));

        if (s_status == ICreditAccount.Status.CLOSED) {
            currentBalanceAmount += s_lenderAfterClosedWithdrawnAmount;
        }
        return currentBalanceAmount;
    }

    /// @notice Transfers tokens from the credit account
    /// @param recipient The transfer recipient
    /// @param amount The amount to transfer
    function _transferFromAccount(address recipient, uint256 amount) internal {
        if (_isETHDenominated()) {
            (bool success,) = recipient.call{value: amount}("");
            if (!success) revert FailedToWithdrawETH();
        } else {
            IERC20 token = IERC20(s_terms.token);
            token.safeTransfer(recipient, amount);
        }
    }

    /// @notice Burns the share of a lender's LP tokens
    /// @return The amount they are owed
    function _withdrawLender(uint256 amountLP) internal returns (uint256) {
        uint256 share = balanceOf(msg.sender);
        if (amountLP > share) revert InsufficientWithdrawableAmount(share, amountLP);

        uint256 withdrawableAmount = amountLP * _getTotalLenderWithdrawableAmount() / totalSupply();
        _burn(msg.sender, amountLP);
        s_status == ICreditAccount.Status.CREATED
            ? s_fundedPrincipalAmount -= withdrawableAmount
            : s_lenderAfterClosedWithdrawnAmount += withdrawableAmount;
        return withdrawableAmount;
    }

    /// @notice Calculates the amount a borrower is can withdraw
    /// @return The amount the borrower can withdraw
    function _withdrawBorrower(uint256 withdrawnTokenAmount) internal returns (uint256) {
        uint256 borrowerWithdrawableAmount = _getBorrowerWithdrawableAmount();
        if (withdrawnTokenAmount > borrowerWithdrawableAmount) {
            revert InsufficientWithdrawableAmount(borrowerWithdrawableAmount, withdrawnTokenAmount);
        }

        if (s_status == ICreditAccount.Status.CREATED || s_status == ICreditAccount.Status.EMERGENCY_CLOSED) {
            s_borrowerDepositedAmount -= withdrawnTokenAmount;
        }
        return withdrawnTokenAmount;
    }

    /// @notice Returns the total amount the lenders are able to withdraw
    /// @return The total withdrawable amount by the lenders
    function _getTotalLenderWithdrawableAmount() internal view returns (uint256) {
        if (s_status == ICreditAccount.Status.CREATED || s_status == ICreditAccount.Status.EMERGENCY_CLOSED) {
            return s_fundedPrincipalAmount;
        }
        if (s_status == ICreditAccount.Status.ACTIVE) {
            return 0;
        }
        uint256 totalBalanceAmount = _getCreditAccountBalance();
        return Math.min(
            totalBalanceAmount, s_fundedPrincipalAmount + s_terms.interestAmount - s_lenderAfterClosedWithdrawnAmount
        );
    }

    /// @notice Returns the total amount the borrower is able to withdraw
    /// @return The total amount the borrower is able to withdraw
    function _getBorrowerWithdrawableAmount() internal view returns (uint256) {
        if (s_status == ICreditAccount.Status.CREATED || s_status == ICreditAccount.Status.EMERGENCY_CLOSED) {
            return s_borrowerDepositedAmount;
        }
        if (s_status == ICreditAccount.Status.ACTIVE) {
            return 0;
        }
        uint256 lenderTotalWithdrawableAmount = _getTotalLenderWithdrawableAmount();
        uint256 totalBalanceAmount = _getCreditAccountBalance();
        return totalBalanceAmount < lenderTotalWithdrawableAmount
            ? 0
            : totalBalanceAmount - lenderTotalWithdrawableAmount - s_lenderAfterClosedWithdrawnAmount;
    }

    /// @notice Allow the contract to accept ETH
    receive() external payable {}

    //################//
    //    Modifiers   //
    //################//

    /// @notice Modifier to ensure that caller is the borrower
    modifier onlyBorrower() {
        if (msg.sender != address(i_borrower)) revert AccessForbidden();
        _;
    }

    /// @notice Modifier to ensure that caller is a stakerholder in the credit account
    modifier onlyStakeholder() {
        if (msg.sender != owner() && msg.sender != i_borrower && balanceOf(msg.sender) == 0) {
            revert AccessForbidden();
        }
        _;
    }

    /// @notice Modifier to ensure that the credit account is currently in a
    /// speficic state
    modifier whenInStatus(ICreditAccount.Status status) {
        if (s_status != status) {
            revert InvalidStatus(s_status);
        }
        _;
    }

    /// @notice Modifier to ensure that the credit account is currently not in a
    /// speficic state
    modifier whenNotInStatus(ICreditAccount.Status status) {
        if (s_status == status) {
            revert InvalidStatus(status);
        }
        _;
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {CreditAccountAccessControl} from "./utils/CreditAccountAccessControl.sol";
import {RevenueEscrow} from "./utils/RevenueEscrow.sol";

interface ICreditAccount {
    /// @notice The statuses of the credit account
    enum Status {
        CREATED,
        ACTIVE,
        CLOSED,
        EMERGENCY_CLOSED
    }

    /// @notice The term parameters for the credit account
    struct Terms {
        /// @notice The amount of time the credit account
        /// is active
        uint256 tenor;
        /// @notice The minimum amount of tokens required
        /// to open the account
        uint256 principalAmount;
        /// @notice The amount the lender expects as
        /// interest
        uint256 interestAmount;
        /// @notice The amount the borrower needs to deposit
        /// as the security deposit
        uint256 securityDepositAmount;
        /// @notice The token the credit account's loan
        /// is denominated in
        address token;
    }

    //################//
    //     Errors     //
    //################//

    /// @notice This error is thrown whenever an address
    /// attemptes to call a function is does not have
    /// authorization to call
    error AccessForbidden();

    /// @notice This error is thrown whenever the tenor
    /// the account is initialized with is zero
    error InvalidTenor();

    /// @notice This error is thrown whenever the principal
    /// the account is initialized with is zero
    error InvalidPrincipalAmount();

    /// @notice This error is thrown whenever the interest
    /// the account is initialized with is zero
    error InvalidInterestAmount();

    /// @notice This error is thrown whenever the credit
    /// an actor tries to start the loan before either
    /// revenue is not fully escrowed or the borrower
    /// has not deposited sufficient interest or the security deposit
    error LoanNotCollateralized();

    /// @notice This error is thrown whenever an actor tries
    /// to start the loan before lenders deposit sufficient
    /// principal.
    /// @param requiredPrincipal The amount of principal required to
    /// start the account
    /// @param currentPrincipal The amount of principal the lenders
    /// have already deposited in the account
    error InsufficientPrincipal(uint256 requiredPrincipal, uint256 currentPrincipal);

    /// @notice This error is thrown whenever a borrower or lender tries
    /// to withdraw more than their withdrawable amount
    /// @param maximumWithdrawableAmount The maximum amount the withdrawer can withdraw
    /// @param withdrawnAmount The amount that the withdrawer is trying to withdraw
    error InsufficientWithdrawableAmount(uint256 maximumWithdrawableAmount, uint256 withdrawnAmount);

    /// @notice This error is thrown whenever a function
    /// is called that requires the account's loan
    /// to have been matured
    /// @param maturityDate The account's loan's
    /// maturity date
    error LoanNotMatured(uint256 maturityDate);

    /// @notice This error is thrown whenever a function
    /// is called whilst the account is in an invalid
    /// status
    /// @param currentStatus The current status of the
    /// credit account
    error InvalidStatus(Status currentStatus);

    /// @notice This error is thrown whenever the
    /// contract fails to withdraw ETH for the
    /// sender
    error FailedToWithdrawETH();

    /// @notice This error is thrown whenever an actor tries to withdraw
    /// a zero amount
    error InvalidWithdrawableAmount();

    /// @notice This error is thrown whenever an actor tries to deposit
    /// a zero amount
    error InvalidDepositAmount();

    //################//
    //     Events     //
    //################//

    /// @notice This event is emitted when the credit account is
    /// opened
    /// @param maturityDate The maturity date of the credit
    /// account's loan
    event CreditAccountOpened(uint256 maturityDate);

    /// @notice This event is emitted when the credit account is
    /// closed
    event CreditAccountClosed();

    /// @notice This event is emitted when the credit account is
    /// emergency closed
    event CreditAccountEmergencyClosed();

    /// @notice This event is emitted when an address deposits
    /// into the credit account
    /// @param depositor The address depositing into the credit account
    /// @param amount The amount deposited
    event CreditAccountDeposited(address indexed depositor, uint256 amount);

    /// @notice This event is emitted when an address withdraws from
    /// the credit account
    /// @param withdrawer The address withdrawing from the credit account
    /// @param amount The amount withdrawn
    event CreditAccountWithdrawn(address indexed withdrawer, uint256 amount);

    //################//
    //     Loans      //
    //################//

    /// @notice Opens the credit account
    function open() external;

    /// @notice Closes the credit account
    function close() external;

    /// @notice Emergency closes the credit account
    function emergencyClose() external;

    /// @notice Deposits into the credit account
    /// @param amount The amount to deposit into the
    /// credit account
    /// @dev If the credit account is denominated in ETH then
    /// amount will be overridden by msg.value
    function deposit(uint256 amount) external payable;

    /// @notice Withdraws from the credit account
    /// @param amount The amount to withdraw.  This will
    /// be the amount of tokens to withdraw if sent by the borrower
    /// or the amount of shares to burn in exchange for the underlying
    /// token if sent by a lender
    function withdraw(uint256 amount) external;

    /// @notice Pauses the credit account
    function emergencyPause() external;

    /// @notice Unpauses the credit account
    function emergencyUnpause() external;

    /// @notice Returns the credit account's terms
    /// @return The terms of the credit account
    function getTerms() external view returns (Terms memory);

    /// @notice Returns the credit account's loan maturity date
    /// @return The maturity date of the credit account's loan
    function getMaturityDate() external view returns (uint256);

    /// @notice Returns the status of the credit account
    /// @return The current status of the credit account
    function getStatus() external view returns (Status);

    /// @notice Returns the total amount the lenders are able to withdraw
    /// @return The total withdrawable amount by the lenders
    function getTotalLenderWithdrawableAmount() external view returns (uint256);

    /// @notice Returns the total amount the borrower is able to withdraw
    /// @return The total amount the borrower is able to withdraw
    function getBorrowerWithdrawableAmount() external view returns (uint256);

    /// @notice Returns the amount an address is able to withdraw
    /// @param withdrawer The address to query for
    /// @return The amount the queried address is able to withdraw
    function getWithdrawableAmount(address withdrawer) external view returns (uint256);

    /// @notice Returns the amount of principal that has been funded
    /// @return The total amount of principal the credit account has been funded with
    function getTotalFundedPrincipalAmount() external view returns (uint256);

    /// @notice Returns the amount the borrower has funded the credit account with
    /// @return The amount the borrower has funded the credit account with
    function getBorrowerFundedAmount() external view returns (uint256);

    //################//
    // Credit Account //
    //################//

    /// @notice Toggles a set of actions to either whitelist or unwhitelist them
    /// @param actions The set of actions to toggle whitelisting for
    function toggleWhitelist(CreditAccountAccessControl.Action[] calldata actions) external;

    /// @notice Executes a set of actions as the credit account
    /// @param executeActions The set of actions to execute
    function execute(CreditAccountAccessControl.ExecuteAction[] calldata executeActions) external;

    /// @notice Returns true if an action is callable by a caller at a target
    /// @param target The target being called
    /// @param caller The caller calling the action on the target
    /// @param fnSelector The action's function selector
    /// @return bool True if the caller is able to call the function at the target
    function isWhitelisted(address target, address caller, bytes4 fnSelector) external view returns (bool);

    /// @notice Toggles a list of actions to be blacklisted or not when the account is closed or paused
    /// @param blacklistedActions The list of blacklisted actions
    function toggleBlacklistedWhenClosedActions(
        CreditAccountAccessControl.BlacklistedOnClosedAction[] calldata blacklistedActions
    ) external;

    /// @notice Returns true if an action is blacklisted when the credit account is closed
    /// @param fn The function being queried for
    /// @return bool True if the function is blacklisted when the credit account is closed
    function isBlacklistedWhenClosed(bytes4 fn) external view returns (bool);

    // ################# //
    //  Revenue Escrow   //
    // ################# //

    /// @notice Adds a set of contracts that needs to be escrowed in order for the credit account
    /// to be considered fully escrowed
    /// @param escrowedContracts The list of contracts that need to be escrowed
    function addEscrowedContracts(RevenueEscrow.EscrowedContractParams[] calldata escrowedContracts) external;

    /// @notice Removes a set of contracts that need to be escrowed in order for the credit account
    /// to be considered fully escrowed
    /// @param escrowedContracts The list of contracts to be removed from the list of required
    /// contracts for escrow
    function removeEscrowedContracts(address[] calldata escrowedContracts) external;

    /// @notice Marks a contract as being escrowed
    /// @param target The target contract that is being escrowed
    function escrowContract(address target) external;

    /// @notice Releases a set of contracts from being escrowed
    /// @param targets The list of contracts to be released from escrow
    function releaseEscrow(address[] calldata targets) external;

    /// @notice Returns true if the credit account has fully escrowed
    /// the borrower's protocol
    function isFullyEscrowed() external view returns (bool);

    /// @notice Returns true if the target contract is currently pending escrow
    /// @param target The target contract being queried for
    /// @return bool True if the target contract is currently pending escrow
    function isPendingEscrow(address target) external view returns (bool);

    /// @notice Returns true if the target contract is currently escrowed by
    /// the credit account
    /// @param target The target contract being queried for
    /// @return bool True if the target contract is currently escrowed
    /// by the credit account
    function isEscrowed(address target) external view returns (bool);

    /// @notice Returns the current state of the revenue escrow
    /// @return uint256 The number of contracts currently escrowed
    /// @return uint256 The number of contracts pending escrow
    function getRevenueEscrowState() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

abstract contract CreditAccountAccessControl {
    /// @notice Parameters for an action that
    /// requires access control
    struct Action {
        /// @notice The caller of the action
        address caller;
        /// @notice The target of the action
        address target;
        /// @notice The function that the action
        /// will call
        bytes4 fnSelector;
        /// @notice True if the action is whitelisted
        bool isWhitelisted;
    }

    /// @notice Parameters for executing an action
    struct ExecuteAction {
        /// @notice The target address the action will call
        address target;
        /// @notice The action's calldata
        bytes data;
        /// @notice The amount of wei to send when executing
        /// the action
        uint256 value;
    }

    /// @notice Parameters for setting whether or not an action
    /// is blacklisted when the account is closed or paused
    struct BlacklistedOnClosedAction {
        /// @notice The action's function selector
        bytes4 action;
        /// @notice True if the action should be blacklisted
        bool isBlacklisted;
    }

    /// @notice The current state of the credit account's
    /// access control
    struct CreditAccountAccessControlState {
        /// @notice Mapping between action IDs to whether
        /// or not they are whitelisted
        mapping(bytes32 => bool) isWhitelisted;
        /// @notice Mapping between function selectors
        /// and whether or not they are blacklisted when the credit
        /// account is closed
        mapping(bytes4 => bool) isBlacklistedWhenClosed;
    }

    //################//
    //     Errors     //
    //################//

    /// @notice This error is thrown whenever a caller tries to execute an action
    /// that they do not have authorization to do
    /// @param target The target address the action is calling
    /// @param caller The address trying to execute the action
    /// @param fnSelector The function the action is trying to execute
    error AccessToCallForbidden(address target, address caller, bytes4 fnSelector);

    /// @notice This error is thrown whenever the action being executed fails
    /// @param target The target address the action is calling
    /// @param caller The address trying to execute the action
    /// @param fnSelector The function the action is trying to execute
    error ExecutionFailed(address target, address caller, bytes4 fnSelector);

    //################//
    //     Events     //
    //################//

    /// @notice This event is emitted whenever an action is whitelisted or unwhitelisted
    /// @param target The target address the action is calling
    /// @param caller The address trying to execute the action
    /// @param fnSelector The function the action is trying to execute
    /// @param isWhitelisted True if the action is whitelisted
    event WhitelistedActionChanged(
        address indexed target, address indexed caller, bytes4 fnSelector, bool isWhitelisted
    );

    /// @notice This event is emitted whenever an action is blacklisted or not when the account is closed
    /// @param action The action being blacklisted or not
    /// @param isBlacklisted True if the action is being blacklisted
    event BlacklistedOnClosedActionChanged(bytes4 action, bool isBlacklisted);

    /// @notice The current state of the credit account's access control
    CreditAccountAccessControlState internal s_creditAccountAccessControlState;

    constructor(bytes4[] memory blacklistedFnsOnClose) {
        for (uint256 i; i < blacklistedFnsOnClose.length; ++i) {
            bytes4 fn = blacklistedFnsOnClose[i];
            s_creditAccountAccessControlState.isBlacklistedWhenClosed[fn] = true;
        }
    }

    /// @notice Sets a list of actions to either be blacklisted or not when the account is closed
    /// @param blacklistedActions The list of actions to toggle blacklisting for
    function _setBlacklistedWhenClosedActions(BlacklistedOnClosedAction[] memory blacklistedActions) internal {
        for (uint256 i; i < blacklistedActions.length; ++i) {
            bytes4 action = blacklistedActions[i].action;
            bool isBlacklisted = blacklistedActions[i].isBlacklisted;
            s_creditAccountAccessControlState.isBlacklistedWhenClosed[action] = isBlacklisted;
            emit BlacklistedOnClosedActionChanged(action, isBlacklisted);
        }
    }

    /// @notice Returns true if an action is blacklisted when the credit account is closed
    /// @param fn The function being queried for
    /// @return bool True if the function is blacklisted when the credit account is closed
    function _isBlacklistedWhenClosed(bytes4 fn) internal view returns (bool) {
        return s_creditAccountAccessControlState.isBlacklistedWhenClosed[fn];
    }

    /// @notice Toggles a set of actions to either whitelist or unwhitelist them
    /// @param actions The set of actions to toggle whitelisting for
    function _toggleWhitelist(Action[] calldata actions) internal {
        for (uint256 i; i < actions.length; ++i) {
            Action memory action = actions[i];
            bytes32 actionId = _generateActionId(action.target, action.caller, action.fnSelector);
            s_creditAccountAccessControlState.isWhitelisted[actionId] = action.isWhitelisted;
            emit WhitelistedActionChanged(action.target, action.caller, action.fnSelector, action.isWhitelisted);
        }
    }

    /// @notice Executes a set of actions as the credit account
    /// @param executeActions The set of actions to execute
    /// @param isOwner True if the caller is the credit account's owner
    /// @param isClosedOrPaused True if the credit account is currently closed or paused
    function _execute(ExecuteAction[] calldata executeActions, bool isOwner, bool isClosedOrPaused) internal {
        for (uint256 i; i < executeActions.length; ++i) {
            ExecuteAction memory executeAction = executeActions[i];
            bytes4 fnSelector = bytes4(executeAction.data);
            bytes32 actionId = _generateActionId(executeAction.target, msg.sender, fnSelector);
            if (
                (isClosedOrPaused && _isBlacklistedWhenClosed(fnSelector))
                    || !isOwner && !s_creditAccountAccessControlState.isWhitelisted[actionId]
            ) {
                revert AccessToCallForbidden(executeAction.target, msg.sender, fnSelector);
            }
            (bool success,) = executeAction.target.call{value: executeAction.value}(executeAction.data);
            if (!success) revert ExecutionFailed(executeAction.target, msg.sender, fnSelector);
        }
    }

    /// @notice Returns true if an action is callable by a caller at a target
    /// @param target The target being called
    /// @param caller The caller calling the action on the target
    /// @param fnSelector The action's function selector
    /// @return bool True if the caller is able to call the function at the target
    function _isWhitelisted(address target, address caller, bytes4 fnSelector) internal view returns (bool) {
        return s_creditAccountAccessControlState.isWhitelisted[_generateActionId(target, caller, fnSelector)];
    }

    /// @notice Generates an action ID for an action given it's parameters
    /// @param target The target being called
    /// @param caller The caller calling the action on the target
    /// @param fnSelector The action's function selector
    /// @return bytes32 The keccak256 hash of the action's parameters
    function _generateActionId(address target, address caller, bytes4 fnSelector) internal pure returns (bytes32) {
        return keccak256(abi.encode(target, caller, fnSelector));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

abstract contract RevenueEscrow {
    using SafeERC20 for IERC20;

    /// @notice Params for adding a contract that needs
    /// to be escrowed
    struct EscrowedContractParams {
        /// @notice The address of the contract to be escrowed
        address contractAddress;
        /// @notice The function to transfer ownership
        bytes4 transferOwnershipFn;
        /// @notice The function to fetch the owner of the
        /// contract
        bytes4 getOwnerFn;
    }

    /// @notice Data for an escrowed contract
    struct EscrowedContract {
        /// @notice The function to transfer ownership
        bytes4 transferOwnershipFn;
        /// @notice The function to fetch the owner
        /// of the contract
        bytes4 getOwnerFn;
        /// @notice True if the contract is escrowed
        bool isEscrowed;
    }

    /// @notice The current state of the revenue escrow
    struct RevenueEscrowState {
        /// @notice The number of escrowed contracts
        uint256 numEscrowedContracts;
        /// @notice The number of contracts pending escrow
        uint256 pendingEscrowedContracts;
        /// @notice Mapping between addresses and the escrowed contract's
        /// data
        mapping(address => EscrowedContract) escrowedContracts;
    }

    //################//
    //     Errors     //
    //################//

    /// @notice This error is thrown whenever a function is empty
    error InvalidFn();

    /// @notice This error is thrown whenever an actor tries to add
    /// a duplicate contract to be escrowed
    /// @param target The target contract to be escrowed
    error AlreadyAddedEscrowContract(address target);

    /// @notice This error is thrown whenever the target contract
    /// has not yet been added to the list of pending contracts
    /// to be escrowed
    /// @param target The non escrowed contract address
    error NonExistentEscrowContract(address target);

    /// @notice This error is thrown whenever an actor tries
    /// to remove a contract that is still escrowed
    /// @param target The contract that is still currently in escrow
    error CurrentlyEscrowedContract(address target);

    /// @notice This error is thrown whenever the target
    /// contract is not escrowable
    /// @param target The contract that is not escrowable
    error NotEscrowable(address target);

    /// @notice This error is thrown whenever the revenue
    /// escrow fails to validate whether or not a target
    /// contract is escrowable
    error FailedToValidate(address target);

    /// @notice This error is thrown whenever the revenue
    /// esrow fails to transfer ownership back to the target
    /// @param target The recipient owner's address
    error FailedToTransferOwnership(address target);

    /// @notice The current state of the revenue escrow
    RevenueEscrowState internal s_revenueEscrow;

    //################//
    //   Functions    //
    //################//

    /// @notice Adds a set of contracts that needs to be escrowed in order for the credit account
    /// to be considered fully escrowed
    /// @param escrowedContracts The list of contracts that need to be escrowed
    function _addEscrowedContracts(EscrowedContractParams[] memory escrowedContracts) internal {
        for (uint256 i; i < escrowedContracts.length; ++i) {
            EscrowedContractParams memory params = escrowedContracts[i];
            if (params.transferOwnershipFn == bytes4("") || params.getOwnerFn == bytes4("")) revert InvalidFn();
            if (s_revenueEscrow.escrowedContracts[params.contractAddress].transferOwnershipFn != bytes4("")) {
                revert AlreadyAddedEscrowContract(params.contractAddress);
            }
            s_revenueEscrow.escrowedContracts[params.contractAddress] = EscrowedContract({
                transferOwnershipFn: params.transferOwnershipFn,
                getOwnerFn: params.getOwnerFn,
                isEscrowed: false
            });

            s_revenueEscrow.pendingEscrowedContracts++;
        }
    }

    /// @notice Removes a set of contracts that need to be escrowed in order for the credit account
    /// to be considered fully escrowed
    /// @param escrowedContracts The list of contracts to be removed from the list of required
    /// contracts for escrow
    function _removeEscrowedContracts(address[] memory escrowedContracts) internal {
        for (uint256 i; i < escrowedContracts.length; ++i) {
            address contractToRemove = escrowedContracts[i];
            if (s_revenueEscrow.escrowedContracts[contractToRemove].transferOwnershipFn == bytes4("")) {
                revert NonExistentEscrowContract(contractToRemove);
            }

            if (s_revenueEscrow.escrowedContracts[contractToRemove].isEscrowed) {
                revert CurrentlyEscrowedContract(contractToRemove);
            }

            s_revenueEscrow.escrowedContracts[contractToRemove] =
                EscrowedContract({transferOwnershipFn: bytes4(""), getOwnerFn: bytes4(""), isEscrowed: false});

            s_revenueEscrow.pendingEscrowedContracts--;
        }
    }

    /// @notice Marks a contract as being escrowed
    /// @param target The target contract that is being escrowed
    function _escrowContract(address target) internal {
        EscrowedContract storage escrowedContract = s_revenueEscrow.escrowedContracts[target];
        if (escrowedContract.getOwnerFn == bytes4("")) revert NonExistentEscrowContract(target);

        s_revenueEscrow.escrowedContracts[target].isEscrowed = true;
        s_revenueEscrow.numEscrowedContracts++;
        s_revenueEscrow.pendingEscrowedContracts--;

        (bool success, bytes memory data) = target.call(abi.encodeWithSelector(escrowedContract.getOwnerFn));

        if (!success) revert FailedToValidate(target);

        // Revenue escrow will only work if the getOwnerFn returns the owner's address as the first
        // argument
        (address owner) = abi.decode(data, (address));
        if (owner != address(this)) revert NotEscrowable(target);
    }

    /// @notice Returns true if the credit account has fully escrowed
    /// the borrower's protocol
    function _isFullyEscrowed() internal view returns (bool) {
        // Must escrow at least 1 contract
        return s_revenueEscrow.pendingEscrowedContracts == 0 && s_revenueEscrow.numEscrowedContracts > 0;
    }

    /// @notice Releases a set of contracts from being escrowed
    /// @param targets The list of contracts to be released from escrow
    /// @param borrower The borrower's address
    function _releaseFromEscrow(address[] memory targets, address borrower) internal {
        for (uint256 i; i < targets.length; ++i) {
            EscrowedContract storage escrowedContract = s_revenueEscrow.escrowedContracts[targets[i]];
            if (escrowedContract.transferOwnershipFn == bytes4("")) {
                revert NonExistentEscrowContract(targets[i]);
            }

            (bool success,) = targets[i].call(abi.encodeWithSelector(escrowedContract.transferOwnershipFn, borrower));
            if (!success) revert FailedToTransferOwnership(targets[i]);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
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