/**
 *Submitted for verification at arbiscan.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract DollarMaxiVault {
    address public governance;
    address public proposedGovernance;
    address public token;
    uint256 public accountCap = 25 * 1e18; //25 token cap per account
    uint256 public vaultCap = 10_000 * 1e18;
    bool public withdrawEnabled = false;
    bool public depositEnabled = true;
    mapping(address => uint256) public balances;

    uint256 public totalCollateral;
    uint256 public totalYield;

    event Withdraw(address, uint256);
    event Deposit(address, uint256);
    event GovernanceWithdraw(address, uint256);
    event GovernanceDeposit(address, uint256);
    event GovernanceProposed(address);
    event GovernanceChanged(address);

    constructor(address _governance, address _token) {
        governance = _governance;
        token = _token;
    }

    function deposit(uint256 _amt) external {
        require(depositEnabled == true, "Deposit not enabled");
        require(totalCollateral + _amt <= vaultCap, "Vault cap exceeded");
        require(
            balances[msg.sender] + _amt <= accountCap,
            "Account cap exceeded"
        );

        balances[msg.sender] += _amt;
        totalCollateral += _amt;

        IERC20(token).transferFrom(msg.sender, address(this), _amt);
        emit Deposit(msg.sender, _amt);
    }

    function withdraw() external {
        require(withdrawEnabled == true, "Withdraw not enabled");
        require(balances[msg.sender] > 0, "No balance found");
        uint256 withdrawAmt = calculateWithdrawableAmount();
        balances[msg.sender] = 0;

        IERC20(token).transfer(msg.sender, withdrawAmt);

        emit Withdraw(msg.sender, withdrawAmt);
    }

    function calculateWithdrawableAmount() public view returns (uint256) {
        uint256 userDeposit = balances[msg.sender];
        require(
            withdrawEnabled && userDeposit > 0 && totalCollateral > 0,
            "soon"
        );

        uint256 userYield = totalYield > 0
            ? (((userDeposit * 1e8) / totalCollateral) * totalYield) / 1e8
            : 0;

        return userDeposit + userYield;
    }

    // ** GOVERNANCE FUNCTIONS ** //
    function setCap(uint256 _newVaultCap, uint256 _newAccountCap)
        external
        onlyGovernance
    {
        require(_newVaultCap >= totalCollateral, "Vault cap too low");

        if (_newVaultCap != vaultCap) {
            vaultCap = _newVaultCap;
        }

        if (_newAccountCap != accountCap) {
            accountCap = _newAccountCap;
        }
    }

    function governanceWithdrawAll() external onlyGovernance {
        depositEnabled = false;
        uint256 amt = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(governance, amt);
        emit GovernanceWithdraw(governance, amt);
    }

    function setWithdrawEnabled(bool _withdrawEnabled) external onlyGovernance {
        withdrawEnabled = _withdrawEnabled;
    }

    function setDepositEnabled(bool _depositEnabled) external onlyGovernance {
        depositEnabled = _depositEnabled;
    }

    function governanceDeposit(uint256 _amt) external onlyGovernance {
        require(_amt >= totalCollateral, "Insufficient deposit");

        totalYield = _amt - totalCollateral;

        IERC20(token).transferFrom(governance, address(this), _amt);

        emit GovernanceDeposit(governance, _amt);
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Not Governance");
        _;
    }

    modifier onlyProposedGovernance() {
        require(msg.sender == proposedGovernance, "Not Proposed Governance");
        _;
    }

    function proposeGovernance(address _proposedGovernanceAddr)
        external
        onlyGovernance
    {
        require(_proposedGovernanceAddr != address(0));
        proposedGovernance = _proposedGovernanceAddr;
        emit GovernanceProposed(_proposedGovernanceAddr);
    }

    function claimGovernance() external onlyProposedGovernance {
        governance = proposedGovernance;
        proposedGovernance = address(0);
        emit GovernanceChanged(governance);
    }
}