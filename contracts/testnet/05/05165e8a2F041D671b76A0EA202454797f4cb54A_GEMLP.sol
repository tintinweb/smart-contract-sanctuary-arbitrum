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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/core/IVaultAccessControlRegistry.sol";

pragma solidity 0.8.19;

contract AccessControlBase is Context {
    IVaultAccessControlRegistry public immutable registry;
    address public immutable timelockAddressImmutable;

    constructor(address _vaultRegistry, address _timelock) {
        registry = IVaultAccessControlRegistry(_vaultRegistry);
        timelockAddressImmutable = _timelock;
    }

    /*==================== Managed in VaultAccessControlRegistry *====================*/

    modifier onlyGovernance() {
        require(
            registry.isCallerGovernance(_msgSender()),
            "Forbidden: Only Governance"
        );
        _;
    }

    modifier onlyEmergency() {
        require(
            registry.isCallerEmergency(_msgSender()),
            "Forbidden: Only Emergency"
        );
        _;
    }

    modifier onlySupport() {
        require(
            registry.isCallerSupport(_msgSender()),
            "Forbidden: Only Support"
        );
        _;
    }

    modifier onlyTeam() {
        require(registry.isCallerTeam(_msgSender()), "Forbidden: Only Team");
        _;
    }

    modifier onlyProtocol() {
        require(
            registry.isCallerProtocol(_msgSender()),
            "Forbidden: Only Protocol"
        );
        _;
    }

    modifier protocolNotPaused() {
        require(!registry.isProtocolPaused(), "Forbidden: Protocol Paused");
        _;
    }

    /*==================== Managed in GEMBTimelock *====================*/

    modifier onlyTimelockGovernance() {
        address timelockActive_;
        if (!registry.timelockActivated()) {
            // the flip is not switched yet, so this means that the governance address can still pass the onlyTimelockGoverance modifier
            timelockActive_ = registry.governanceAddress();
        } else {
            // the flip is switched, the immutable timelock is now locked in as the only adddress that can pass this modifier (and nothing can undo that)
            timelockActive_ = timelockAddressImmutable;
        }
        require(
            _msgSender() == timelockActive_,
            "Forbidden: Only TimelockGovernance"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/IAccessControl.sol";

pragma solidity >=0.6.0 <0.9.0;

interface IVaultAccessControlRegistry is IAccessControl {
	function timelockActivated() external view returns (bool);

	function governanceAddress() external view returns (address);

	function pauseProtocol() external;

	function unpauseProtocol() external;

	function isCallerGovernance(address _account) external view returns (bool);

	function isCallerEmergency(address _account) external view returns (bool);

	function isCallerProtocol(address _account) external view returns (bool);

	function isCallerTeam(address _account) external view returns (bool);

	function isCallerSupport(address _account) external view returns (bool);

	function isProtocolPaused() external view returns (bool);

	function changeGovernanceAddress(address _governanceAddress) external;

	/*==================== Events *====================*/

	event DeadmanSwitchFlipped();
	event GovernanceChange(address newGovernanceAddress);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IMintable {
	event MinterSet(address minterAddress, bool isActive);

	function isMinter(address _account) external returns (bool);

	function setMinter(address _minter, bool _isActive) external;

	function mint(address _account, uint256 _amount) external;

	function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IBaseFDT.sol";
import "./math/SafeMath.sol";
import "./math/SignedSafeMath.sol";
import "./math/SafeMathUint.sol";
import "./math/SafeMathInt.sol";

/// @title BasicFDT implements base level FDT functionality for accounting for revenues.
abstract contract BasicFDT is IBaseFDT, ERC20 {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SignedSafeMath for int256;
    using SafeMathInt for int256;

    uint256 internal constant pointsMultiplier = 2 ** 128;

    // storage for GEMLP token rewards
    uint256 internal pointsPerShare_GEMLP;
    mapping(address => int256) internal pointsCorrection_GEMLP;
    mapping(address => uint256) internal withdrawnFunds_GEMLP;

    // storage for VGEMB token rewards
    uint256 internal pointsPerShare_VGEMB;
    mapping(address => int256) internal pointsCorrection_VGEMB;
    mapping(address => uint256) internal withdrawnFunds_VGEMB;

    // events GEMLP token rewards
    event PointsPerShareUpdated_GEMLP(uint256 pointsPerShare_GEMLP);
    event PointsCorrectionUpdated_GEMLP(
        address indexed account,
        int256 pointsCorrection_GEMLP
    );

    // events VGEMB token rewards
    event PointsPerShareUpdated_VGEMB(uint256 pointsPerShare_VGEMB);
    event PointsCorrectionUpdated_VGEMB(
        address indexed account,
        int256 pointsCorrection_VGEMB
    );

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    // ADDED FUNCTION BY GHOST

    /**
     * The GEMLP on this contract (so that is GEMLP that has to be disbtributed as rewards, doesn't belong the the GEMLP that can claim this same WLp). To prevent the dust accumulation of GEMLP on this contract, we should deduct the balance of GEMLP on this contract from totalSupply, otherwise the pointsPerShare_GEMLP will make pointsPerShare_GEMLP lower as it should be
     */
    function correctedTotalSupply() public view returns (uint256) {
        return (totalSupply() - balanceOf(address(this)));
    }

    /**
        @dev Distributes funds to token holders.
        @dev It reverts if the total supply of tokens is 0.
        @dev It emits a `FundsDistributed` event if the amount of received funds is greater than 0.
        @dev It emits a `PointsPerShareUpdated` event if the amount of received funds is greater than 0.
             About undistributed funds:
                In each distribution, there is a small amount of funds which do not get distributed,
                   which is `(value  pointsMultiplier) % totalSupply()`.
                With a well-chosen `pointsMultiplier`, the amount funds that are not getting distributed
                   in a distribution can be less than 1 (base unit).
                We can actually keep track of the undistributed funds in a distribution
                   and try to distribute it in the next distribution.
    */
    function _distributeFunds_GEMLP(uint256 value) internal {
        require(totalSupply() > 0, "FDT:ZERO_SUPPLY");

        if (value == 0) return;

        uint256 correctedTotalSupply_ = correctedTotalSupply();

        pointsPerShare_GEMLP = pointsPerShare_GEMLP.add(
            value.mul(pointsMultiplier) / correctedTotalSupply_
        );
        emit FundsDistributed_GEMLP(msg.sender, value);
        emit PointsPerShareUpdated_GEMLP(pointsPerShare_GEMLP);
    }

    function _distributeFunds_VGEMB(uint256 value) internal {
        require(totalSupply() > 0, "FDT:ZERO_SUPPLY");

        if (value == 0) return;

        uint256 correctedTotalSupply_ = correctedTotalSupply();

        pointsPerShare_VGEMB = pointsPerShare_VGEMB.add(
            value.mul(pointsMultiplier) / correctedTotalSupply_
        );
        emit FundsDistributed_VGEMB(msg.sender, value);
        emit PointsPerShareUpdated_VGEMB(pointsPerShare_VGEMB);
    }

    /**
        @dev    Prepares the withdrawal of funds.
        @dev    It emits a `FundsWithdrawn_GEMLP` event if the amount of withdrawn funds is greater than 0.
        @return withdrawableDividend_GEMLP The amount of dividend funds that can be withdrawn.
    */
    function _prepareWithdraw_GEMLP()
        internal
        returns (uint256 withdrawableDividend_GEMLP)
    {
        withdrawableDividend_GEMLP = withdrawableFundsOf_GEMLP(msg.sender);
        uint256 _withdrawnFunds_GEMLP = withdrawnFunds_GEMLP[msg.sender].add(
            withdrawableDividend_GEMLP
        );
        withdrawnFunds_GEMLP[msg.sender] = _withdrawnFunds_GEMLP;
        emit FundsWithdrawn_GEMLP(
            msg.sender,
            withdrawableDividend_GEMLP,
            _withdrawnFunds_GEMLP
        );
    }

    function _prepareWithdraw_VGEMB()
        internal
        returns (uint256 withdrawableDividend_VGEMB)
    {
        withdrawableDividend_VGEMB = withdrawableFundsOf_VGEMB(msg.sender);
        uint256 _withdrawnFunds_VGEMB = withdrawnFunds_VGEMB[msg.sender].add(
            withdrawableDividend_VGEMB
        );
        withdrawnFunds_VGEMB[msg.sender] = _withdrawnFunds_VGEMB;
        emit FundsWithdrawn_VGEMB(
            msg.sender,
            withdrawableDividend_VGEMB,
            _withdrawnFunds_VGEMB
        );
    }

    /**
        @dev    Returns the amount of funds that an account can withdraw.
        @param  _owner The address of a token holder.
        @return The amount funds that `_owner` can withdraw.
    */
    function withdrawableFundsOf_GEMLP(
        address _owner
    ) public view returns (uint256) {
        return
            accumulativeFundsOf_GEMLP(_owner).sub(withdrawnFunds_GEMLP[_owner]);
    }

    function withdrawableFundsOf_VGEMB(
        address _owner
    ) public view returns (uint256) {
        return
            accumulativeFundsOf_VGEMB(_owner).sub(withdrawnFunds_VGEMB[_owner]);
    }

    /**
        @dev    Returns the amount of funds that an account has withdrawn.
        @param  _owner The address of a token holder.
        @return The amount of funds that `_owner` has withdrawn.
    */
    function withdrawnFundsOf_GEMLP(
        address _owner
    ) external view returns (uint256) {
        return withdrawnFunds_GEMLP[_owner];
    }

    function withdrawnFundsOf_VGEMB(
        address _owner
    ) external view returns (uint256) {
        return withdrawnFunds_VGEMB[_owner];
    }

    /**
        @dev    Returns the amount of funds that an account has earned in total.
        @dev    accumulativeFundsOf_GEMLP(_owner) = withdrawableFundsOf_GEMLP(_owner) + withdrawnFundsOf_GEMLP(_owner)
                                         = (pointsPerShare_GEMLP * balanceOf(_owner) + pointsCorrection_GEMLP[_owner]) / pointsMultiplier
        @param  _owner The address of a token holder.
        @return The amount of funds that `_owner` has earned in total.
    */
    function accumulativeFundsOf_GEMLP(
        address _owner
    ) public view returns (uint256) {
        return
            pointsPerShare_GEMLP
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(pointsCorrection_GEMLP[_owner])
                .toUint256Safe() / pointsMultiplier;
    }

    function accumulativeFundsOf_VGEMB(
        address _owner
    ) public view returns (uint256) {
        return
            pointsPerShare_VGEMB
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(pointsCorrection_VGEMB[_owner])
                .toUint256Safe() / pointsMultiplier;
    }

    /**
        @dev   Transfers tokens from one account to another. Updates pointsCorrection_GEMLP to keep funds unchanged.
        @dev   It emits two `PointsCorrectionUpdated` events, one for the sender and one for the receiver.
        @param from  The address to transfer from.
        @param to    The address to transfer to.
        @param value The amount to be transferred.
    */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        super._transfer(from, to, value);

        // storage for GEMLP token rewards
        int256 _magCorrection_GEMLP = pointsPerShare_GEMLP
            .mul(value)
            .toInt256Safe();
        int256 pointsCorrectionFrom_GEMLP = pointsCorrection_GEMLP[from].add(
            _magCorrection_GEMLP
        );
        pointsCorrection_GEMLP[from] = pointsCorrectionFrom_GEMLP;
        int256 pointsCorrectionTo_GEMLP = pointsCorrection_GEMLP[to].sub(
            _magCorrection_GEMLP
        );
        pointsCorrection_GEMLP[to] = pointsCorrectionTo_GEMLP;

        // storage for VGEMB token rewards
        int256 _magCorrection_VGEMB = pointsPerShare_VGEMB
            .mul(value)
            .toInt256Safe();
        int256 pointsCorrectionFrom_VGEMB = pointsCorrection_VGEMB[from].add(
            _magCorrection_VGEMB
        );
        pointsCorrection_VGEMB[from] = pointsCorrectionFrom_VGEMB;
        int256 pointsCorrectionTo_VGEMB = pointsCorrection_VGEMB[to].sub(
            _magCorrection_VGEMB
        );
        pointsCorrection_VGEMB[to] = pointsCorrectionTo_VGEMB;

        emit PointsCorrectionUpdated_GEMLP(from, pointsCorrectionFrom_GEMLP);
        emit PointsCorrectionUpdated_GEMLP(to, pointsCorrectionTo_GEMLP);

        emit PointsCorrectionUpdated_VGEMB(from, pointsCorrectionFrom_VGEMB);
        emit PointsCorrectionUpdated_VGEMB(to, pointsCorrectionTo_VGEMB);
    }

    /**
        @dev   Mints tokens to an account. Updates pointsCorrection_GEMLP to keep funds unchanged.
        @param account The account that will receive the created tokens.
        @param value   The amount that will be created.
    */
    function _mint(address account, uint256 value) internal virtual override {
        super._mint(account, value);

        int256 _pointsCorrection_GEMLP = pointsCorrection_GEMLP[account].sub(
            (pointsPerShare_GEMLP.mul(value)).toInt256Safe()
        );

        pointsCorrection_GEMLP[account] = _pointsCorrection_GEMLP;

        int256 _pointsCorrection_VGEMB = pointsCorrection_VGEMB[account].sub(
            (pointsPerShare_VGEMB.mul(value)).toInt256Safe()
        );

        pointsCorrection_VGEMB[account] = _pointsCorrection_VGEMB;

        emit PointsCorrectionUpdated_GEMLP(account, _pointsCorrection_GEMLP);
        emit PointsCorrectionUpdated_VGEMB(account, _pointsCorrection_VGEMB);
    }

    /**
        @dev   Burns an amount of the token of a given account. Updates pointsCorrection_GEMLP to keep funds unchanged.
        @dev   It emits a `PointsCorrectionUpdated` event.
        @param account The account whose tokens will be burnt.
        @param value   The amount that will be burnt.
    */
    function _burn(address account, uint256 value) internal virtual override {
        super._burn(account, value);

        int256 _pointsCorrection_GEMLP = pointsCorrection_GEMLP[account].add(
            (pointsPerShare_GEMLP.mul(value)).toInt256Safe()
        );

        pointsCorrection_GEMLP[account] = _pointsCorrection_GEMLP;

        int256 _pointsCorrection_VGEMB = pointsCorrection_VGEMB[account].add(
            (pointsPerShare_VGEMB.mul(value)).toInt256Safe()
        );

        pointsCorrection_VGEMB[account] = _pointsCorrection_VGEMB;

        emit PointsCorrectionUpdated_GEMLP(account, _pointsCorrection_GEMLP);
        emit PointsCorrectionUpdated_VGEMB(account, _pointsCorrection_VGEMB);
    }

    /**
        @dev Withdraws all available funds for a token holder.
    */
    function withdrawFunds_GEMLP() public virtual override {}

    function withdrawFunds_VGEMB() public virtual override {}

    function withdrawFunds() public virtual override {}

    /**
        @dev    Updates the current `fundsToken` balance and returns the difference of the new and previous `fundsToken` balance.
        @return A int256 representing the difference of the new and previous `fundsToken` balance.
    */
    function _updateFundsTokenBalance_GEMLP()
        internal
        virtual
        returns (int256)
    {}

    function _updateFundsTokenBalance_VGEMB()
        internal
        virtual
        returns (int256)
    {}

    /**
        @dev Registers a payment of funds in tokens. May be called directly after a deposit is made.
        @dev Calls _updateFundsTokenBalance(), whereby the contract computes the delta of the new and previous
             `fundsToken` balance and increments the total received funds (cumulative), by delta, by calling _distributeFunds_GEMLP().
    */
    function updateFundsReceived() public virtual {
        int256 newFunds_GEMLP = _updateFundsTokenBalance_GEMLP();
        int256 newFunds_VGEMB = _updateFundsTokenBalance_VGEMB();

        if (newFunds_GEMLP > 0) {
            _distributeFunds_GEMLP(newFunds_GEMLP.toUint256Safe());
        }

        if (newFunds_VGEMB > 0) {
            _distributeFunds_VGEMB(newFunds_VGEMB.toUint256Safe());
        }
    }

    function updateFundsReceived_GEMLP() public virtual {
        int256 newFunds_GEMLP = _updateFundsTokenBalance_GEMLP();

        if (newFunds_GEMLP > 0) {
            _distributeFunds_GEMLP(newFunds_GEMLP.toUint256Safe());
        }
    }

    function updateFundsReceived_VGEMB() public virtual {
        int256 newFunds_VGEMB = _updateFundsTokenBalance_VGEMB();

        if (newFunds_VGEMB > 0) {
            _distributeFunds_VGEMB(newFunds_VGEMB.toUint256Safe());
        }
    }

    function returnPointsCorrection_GEMLP(
        address _account
    ) public view returns (int256) {
        return pointsCorrection_GEMLP[_account];
    }

    function returnPointsCorrection_VGEMB(
        address _account
    ) public view returns (int256) {
        return pointsCorrection_VGEMB[_account];
    }

    function returnWithdrawnFunds_GEMLP(
        address _account
    ) public view returns (uint256) {
        return withdrawnFunds_GEMLP[_account];
    }

    function returnWithdrawnFunds_VGEMB(
        address _account
    ) public view returns (uint256) {
        return withdrawnFunds_VGEMB[_account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./MintableBaseToken.sol";

contract GEMLP is MintableBaseToken {
    constructor(
        address _vaultRegistry,
        address _timelock,
        address _vGembAddress
    )
        MintableBaseToken(
            "gembit LP",
            "gemLP",
            _vGembAddress,
            _vaultRegistry,
            _timelock
        )
    {}

    function id() external pure returns (string memory _name) {
        return "gemLP";
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface IBaseFDT {
    /**
        @dev    Returns the total amount of funds a given address is able to withdraw currently.
        @param  owner Address of FDT holder.
        @return A uint256 representing the available funds for a given account.
    */
    function withdrawableFundsOf_GEMLP(
        address owner
    ) external view returns (uint256);

    function withdrawableFundsOf_VGEMB(
        address owner
    ) external view returns (uint256);

    /**
        @dev Withdraws all available funds for a FDT holder.
    */
    function withdrawFunds_GEMLP() external;

    function withdrawFunds_VGEMB() external;

    function withdrawFunds() external;

    /**
        @dev   This event emits when new funds are distributed.
        @param by               The address of the sender that distributed funds.
        @param fundsDistributed_GEMLP The amount of funds received for distribution.
    */
    event FundsDistributed_GEMLP(
        address indexed by,
        uint256 fundsDistributed_GEMLP
    );

    event FundsDistributed_VGEMB(
        address indexed by,
        uint256 fundsDistributed_VGEMB
    );

    /**
        @dev   This event emits when distributed funds are withdrawn by a token holder.
        @param by             The address of the receiver of funds.
        @param fundsWithdrawn_GEMLP The amount of funds that were withdrawn.
        @param totalWithdrawn_GEMLP The total amount of funds that were withdrawn.
    */
    event FundsWithdrawn_GEMLP(
        address indexed by,
        uint256 fundsWithdrawn_GEMLP,
        uint256 totalWithdrawn_GEMLP
    );

    event FundsWithdrawn_VGEMB(
        address indexed by,
        uint256 fundsWithdrawn_VGEMB,
        uint256 totalWithdrawn_VGEMB
    );
}

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;
pragma solidity 0.8.19;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");

		return c;
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
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
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
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
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
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");

		return c;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts on
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
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts when dividing by zero.
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
		return mod(a, b, "SafeMath: modulo by zero");
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts with custom message when dividing by zero.
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
		require(b != 0, errorMessage);
		return a % b;
	}
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// pragma solidity 0.6.11;
pragma solidity 0.8.19;

library SafeMathInt {
	function toUint256Safe(int256 a) internal pure returns (uint256) {
		require(a >= 0, "SMI:NEG");
		return uint256(a);
	}
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// pragma solidity 0.6.11;
pragma solidity 0.8.19;

library SafeMathUint {
	function toInt256Safe(uint256 a) internal pure returns (int256 b) {
		b = int256(a);
		require(b >= 0, "SMU:OOB");
	}
}

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;
pragma solidity 0.8.19;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
	int256 private constant _INT256_MIN = -2 ** 255;

	/**
	 * @dev Returns the multiplication of two signed integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `*` operator.
	 *
	 * Requirements:
	 *
	 * - Multiplication cannot overflow.
	 */
	function mul(int256 a, int256 b) internal pure returns (int256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

		int256 c = a * b;
		require(c / a == b, "SignedSafeMath: multiplication overflow");

		return c;
	}

	/**
	 * @dev Returns the integer division of two signed integers. Reverts on
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
	function div(int256 a, int256 b) internal pure returns (int256) {
		require(b != 0, "SignedSafeMath: division by zero");
		require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

		int256 c = a / b;

		return c;
	}

	/**
	 * @dev Returns the subtraction of two signed integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a - b;
		require(
			(b >= 0 && c <= a) || (b < 0 && c > a),
			"SignedSafeMath: subtraction overflow"
		);

		return c;
	}

	/**
	 * @dev Returns the addition of two signed integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
	 *
	 * - Addition cannot overflow.
	 */
	function add(int256 a, int256 b) internal pure returns (int256) {
		int256 c = a + b;
		require(
			(b >= 0 && c >= a) || (b < 0 && c < a),
			"SignedSafeMath: addition overflow"
		);

		return c;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./BasicFDT.sol";
import "../../interfaces/tokens/gemLp/IMintable.sol";
import "../../core/AccessControlBase.sol";
import "solmate/src/utils/ReentrancyGuard.sol";

contract MintableBaseToken is
    BasicFDT,
    AccessControlBase,
    ReentrancyGuard,
    IMintable
{
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SignedSafeMath for int256;
    using SafeMathInt for int256;

    mapping(address => bool) public override isMinter;
    bool public inPrivateTransferMode;
    mapping(address => bool) public isHandler;

    IERC20 public immutable rewardToken_GEMLP; // 1 The `rewardToken_GEMLP` (dividends).
    IERC20 public immutable rewardToken_VGEMB; // 2 The `rewardToken_VGEMB` (dividends).

    uint256 public rewardTokenBalance_GEMLP; // The amount of `rewardToken_GEMLP` (Liquidity Asset 1) currently present and accounted for in this contract.
    uint256 public rewardTokenBalance_VGEMB; // The amount of `rewardToken_VGEMB` (Liquidity Asset2 ) currently present and accounted for in this contract.

    event SetInfo(string name, string symbol);

    event SetPrivateTransferMode(bool inPrivateTransferMode);

    event SetHandler(address handlerAddress, bool isActive);

    event WithdrawStuckToken(
        address tokenAddress,
        address receiver,
        uint256 amount
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address _vgembAddress,
        address _vaultRegistry,
        address _timelock
    ) BasicFDT(_name, _symbol) AccessControlBase(_vaultRegistry, _timelock) {
        rewardToken_GEMLP = IERC20(address(this));
        rewardToken_VGEMB = IERC20(_vgembAddress);
    }

    modifier onlyMinter() {
        require(isMinter[_msgSender()], "MintableBaseToken: forbidden");
        _;
    }

    /**
        @dev Withdraws all available funds for a token holder.
    */
    function withdrawFunds_GEMLP() public virtual override nonReentrant {
        uint256 withdrawableFunds_GEMLP = _prepareWithdraw_GEMLP();

        if (withdrawableFunds_GEMLP > uint256(0)) {
            rewardToken_GEMLP.transfer(_msgSender(), withdrawableFunds_GEMLP);

            _updateFundsTokenBalance_GEMLP();
        }
    }

    function withdrawFunds_VGEMB() public virtual override nonReentrant {
        uint256 withdrawableFunds_VGEMB = _prepareWithdraw_VGEMB();

        if (withdrawableFunds_VGEMB > uint256(0)) {
            rewardToken_VGEMB.transfer(_msgSender(), withdrawableFunds_VGEMB);

            _updateFundsTokenBalance_VGEMB();
        }
    }

    function withdrawFunds() public virtual override nonReentrant {
        withdrawFunds_GEMLP();
        withdrawFunds_VGEMB();
    }

    /**
        @dev    Updates the current `rewardToken_GEMLP` balance and returns the difference of the new and previous `rewardToken_GEMLP` balance.
        @return A int256 representing the difference of the new and previous `rewardToken_GEMLP` balance.
    */
    function _updateFundsTokenBalance_GEMLP()
        internal
        virtual
        override
        returns (int256)
    {
        uint256 _prevFundsTokenBalance_GEMLP = rewardTokenBalance_GEMLP;

        rewardTokenBalance_GEMLP = rewardToken_GEMLP.balanceOf(address(this));

        return
            int256(rewardTokenBalance_GEMLP).sub(
                int256(_prevFundsTokenBalance_GEMLP)
            );
    }

    function _updateFundsTokenBalance_VGEMB()
        internal
        virtual
        override
        returns (int256)
    {
        uint256 _prevFundsTokenBalance_VGEMB = rewardTokenBalance_VGEMB;

        rewardTokenBalance_VGEMB = rewardToken_VGEMB.balanceOf(address(this));

        return
            int256(rewardTokenBalance_VGEMB).sub(
                int256(_prevFundsTokenBalance_VGEMB)
            );
    }

    function transfer(
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        if (inPrivateTransferMode) {
            require(
                isHandler[_msgSender()],
                "BaseToken: _msgSender() not whitelisted"
            );
        }
        super._transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        if (inPrivateTransferMode) {
            require(
                isHandler[_msgSender()],
                "BaseToken: _msgSender() not whitelisted"
            );
        }
        if (isHandler[_msgSender()]) {
            super._transfer(_from, _recipient, _amount);
            return true;
        }
        address spender = _msgSender();
        super._spendAllowance(_from, spender, _amount);
        super._transfer(_from, _recipient, _amount);
        return true;
    }

    function setInPrivateTransferMode(
        bool _inPrivateTransferMode
    ) external onlyTimelockGovernance {
        inPrivateTransferMode = _inPrivateTransferMode;
        emit SetPrivateTransferMode(_inPrivateTransferMode);
    }

    function setHandler(
        address _handler,
        bool _isActive
    ) external onlyTimelockGovernance {
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    function setInfo(
        string memory _name,
        string memory _symbol
    ) external onlyGovernance {
        _name = _name;
        _symbol = _symbol;
        emit SetInfo(_name, _symbol);
    }

    /**
     * @notice function to service users who accidentally send their tokens to this contract
     * @dev since this function could technically steal users assets we added a timelock modifier
     * @param _token address of the token to be recoved
     * @param _account address the recovered tokens will be sent to
     * @param _amount amount of token to be recoverd
     */
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGovernance {
        IERC20(_token).transfer(_account, _amount);
        emit WithdrawStuckToken(_token, _account, _amount);
    }

    function setMinter(
        address _minter,
        bool _isActive
    ) external override onlyTimelockGovernance {
        isMinter[_minter] = _isActive;
        emit MinterSet(_minter, _isActive);
    }

    function mint(
        address _account,
        uint256 _amount
    ) external override nonReentrant onlyMinter {
        super._mint(_account, _amount);
    }

    function burn(
        address _account,
        uint256 _amount
    ) external override nonReentrant onlyMinter {
        super._burn(_account, _amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}