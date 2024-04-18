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