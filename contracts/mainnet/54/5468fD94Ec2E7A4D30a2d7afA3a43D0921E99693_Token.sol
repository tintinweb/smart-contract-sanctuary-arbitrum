// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value at the end of the corresponding block.
     */
    function getPastVotes(address account, uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value at the end of the corresponding block.
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
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
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5805.sol)

pragma solidity ^0.8.0;

import "../governance/utils/IVotes.sol";
import "./IERC6372.sol";

interface IERC5805 is IERC6372, IVotes {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC6372.sol)

pragma solidity ^0.8.0;

interface IERC6372 {
    /**
     * @dev Clock used for flagging checkpoints. Can be overridden to implement timestamp based checkpoints (and voting).
     */
    function clock() external view returns (uint48);

    /**
     * @dev Description of the clock
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;

import "./ERC20Permit.sol";
import "../../../interfaces/IERC5805.sol";
import "../../../utils/math/Math.sol";
import "../../../utils/math/SafeCast.sol";
import "../../../utils/cryptography/ECDSA.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Votes is ERC20Permit, IERC5805 {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Clock used for flagging checkpoints. Can be overridden to implement timestamp based checkpoints (and voting).
     */
    function clock() public view virtual override returns (uint48) {
        return SafeCast.toUint48(block.number);
    }

    /**
     * @dev Description of the clock
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public view virtual override returns (string memory) {
        // Check that the clock was not modified
        require(clock() == block.number, "ERC20Votes: broken clock mode");
        return "mode=blocknumber&from=default";
    }

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual override returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        unchecked {
            return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
        }
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `timepoint`.
     *
     * Requirements:
     *
     * - `timepoint` must be in the past
     */
    function getPastVotes(address account, uint256 timepoint) public view virtual override returns (uint256) {
        require(timepoint < clock(), "ERC20Votes: future lookup");
        return _checkpointsLookup(_checkpoints[account], timepoint);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `timepoint`. Note, this value is the sum of all balances.
     * It is NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `timepoint` must be in the past
     */
    function getPastTotalSupply(uint256 timepoint) public view virtual override returns (uint256) {
        require(timepoint < clock(), "ERC20Votes: future lookup");
        return _checkpointsLookup(_totalSupplyCheckpoints, timepoint);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 timepoint) private view returns (uint256) {
        // We run a binary search to look for the last (most recent) checkpoint taken before (or at) `timepoint`.
        //
        // Initially we check if the block is recent to narrow the search range.
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `timepoint`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `timepoint`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `timepoint`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `timepoint`, but it works out
        // the same.
        uint256 length = ckpts.length;

        uint256 low = 0;
        uint256 high = length;

        if (length > 5) {
            uint256 mid = length - Math.sqrt(length);
            if (_unsafeAccess(ckpts, mid).fromBlock > timepoint) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(ckpts, mid).fromBlock > timepoint) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        unchecked {
            return high == 0 ? 0 : _unsafeAccess(ckpts, high - 1).votes;
        }
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {IVotes-DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {IVotes-DelegateChanged} and {IVotes-DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(address src, address dst, uint256 amount) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;

        unchecked {
            Checkpoint memory oldCkpt = pos == 0 ? Checkpoint(0, 0) : _unsafeAccess(ckpts, pos - 1);

            oldWeight = oldCkpt.votes;
            newWeight = op(oldWeight, delta);

            if (pos > 0 && oldCkpt.fromBlock == clock()) {
                _unsafeAccess(ckpts, pos - 1).votes = SafeCast.toUint224(newWeight);
            } else {
                ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(clock()), votes: SafeCast.toUint224(newWeight)}));
            }
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint[] storage ckpts, uint256 pos) private pure returns (Checkpoint storage result) {
        assembly {
            mstore(0, ckpts.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
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
// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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

pragma solidity 0.8.19;

import '../sharedContracts/PlanDelegator.sol';

abstract contract ERC721Delegate is PlanDelegator {
  event TokenDelegated(uint256 indexed tokenId, address indexed delegate);
  event DelegateRemoved(uint256 indexed tokenId, address indexed delegate);

  function _delegateToken(address delegate, uint256 tokenId) internal {
    require(_isApprovedDelegatorOrOwner(msg.sender, tokenId), '!delegator');
    _transferDelegate(delegate, tokenId);
  }

  // function for minting should add the token to the delegate and increase the balance
  function _addDelegate(address to, uint256 tokenId) private {
    uint256 length = _delegateBalances[to];
    _delegatedTokens[to][length] = tokenId;
    _delegatedTokensIndex[tokenId] = length;
    _delegates[tokenId] = to;
    _delegateBalances[to] += 1;
    emit TokenDelegated(tokenId, to);
  }

  // function for burning should reduce the balances and set the token mapped to 0x0 address
  function _removeDelegate(uint256 tokenId) private {
    address from = delegatedTo(tokenId);
    uint256 lastTokenIndex = _delegateBalances[from] - 1;
    uint256 tokenIndex = _delegatedTokensIndex[tokenId];
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _delegatedTokens[from][lastTokenIndex];
      _delegatedTokens[from][tokenIndex] = lastTokenId;
      _delegatedTokensIndex[lastTokenId] = tokenIndex;
    }
    delete _delegatedTokensIndex[tokenId];
    delete _delegatedTokens[from][lastTokenIndex];
    _delegateBalances[from] -= 1;
    _delegates[tokenId] = address(0);
    emit DelegateRemoved(tokenId, from);
  }

  // function for transfering should reduce the balances of from by 1, increase the balances of to by 1, and set the delegate address To
  function _transferDelegate(address to, uint256 tokenId) internal {
    _removeDelegate(tokenId);
    _addDelegate(to, tokenId);
  }

  //mapping from tokenId to the delegate address
  mapping(uint256 => address) private _delegates;

  // mapping from delegate address to token count
  mapping(address => uint256) private _delegateBalances;

  // mapping from delegate to the list of delegated token Ids
  mapping(address => mapping(uint256 => uint256)) private _delegatedTokens;

  // maping from token ID to the index of the delegates token list
  mapping(uint256 => uint256) private _delegatedTokensIndex;

  function balanceOfDelegate(address delegate) public view returns (uint256) {
    require(delegate != address(0), '!address(0)');
    return _delegateBalances[delegate];
  }

  function delegatedTo(uint256 tokenId) public view returns (address) {
    address delegate = _delegates[tokenId];
    require(delegate != address(0), '!address(0)');
    return delegate;
  }

  function tokenOfDelegateByIndex(address delegate, uint256 index) public view returns (uint256) {
    require(index < _delegateBalances[delegate], 'out of bounds');
    return _delegatedTokens[delegate][index];
  }

  function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
    super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    uint256 tokenId = firstTokenId;
    if (from == address(0)) {
      _addDelegate(to, tokenId);
    }
    if (to == address(0)) { 
      _removeDelegate(tokenId);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Delegate is IERC721, IERC721Enumerable {
  function balanceOfDelegate(address delegate) external view returns (uint256);

  function delegatedTo(uint256 tokenId) external view returns (address);

  function tokenOfDelegateByIndex(address delegate, uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IDelegateNFT {
 
 function delegateTokens(address delegate, uint256[] memory tokenIds) external;

 function delegateAllNFTs(address delegate) external;

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  function tokenByIndex(uint256 index) external view returns (uint256);

  function balanceOfDelegate(address delegate) external view returns (uint256);

  function delegatedTo(uint256 tokenId) external view returns (address);

  function tokenOfDelegateByIndex(address delegate, uint256 index) external view returns (uint256);

  function lockedBalances(address holder, address token) external view returns (uint256);

  function delegatedBalances(address delegate, address token) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface ILockupPlans {
  function createPlan(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 rate,
    uint256 period
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IVestingPlans {
    function createPlan(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 rate,
    uint256 period,
    address vestingAdmin,
    bool adminTransferOBO
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/// @notice Library to assist with calculation methods of the balances, ends, period amounts for a given plan
/// used by both the Lockup and Vesting Plans
library TimelockLibrary {
  function min(uint256 a, uint256 b) internal pure returns (uint256 _min) {
    _min = (a <= b) ? a : b;
  }

  /// @notice function to calculate the end date of a plan based on its start, amount, rate and period
  function endDate(uint256 start, uint256 amount, uint256 rate, uint256 period) internal pure returns (uint256 end) {
    end = (amount % rate == 0) ? (amount / rate) * period + start : ((amount / rate) * period) + period + start;
  }

  /// @notice function to calculate the end period and validate that the parameters passed in are valid
  function validateEnd(
    uint256 start,
    uint256 cliff,
    uint256 amount,
    uint256 rate,
    uint256 period
  ) internal pure returns (uint256 end, bool valid) {
    require(amount > 0, '0_amount');
    require(rate > 0, '0_rate');
    require(rate <= amount, 'rate > amount');
    require(period > 0, '0_period');
    end = (amount % rate == 0) ? (amount / rate) * period + start : ((amount / rate) * period) + period + start;
    require(cliff <= end, 'cliff > end');
    valid = true;
  }

  /// @notice function to calculate the unlocked (claimable) balance, still locked balance, and the most recent timestamp the unlock would take place
  /// the most recent unlock time is based on the periods, so if the periods are 1, then the unlock time will be the same as the redemption time,
  /// however if the period more than 1 second, the latest unlock will be a discrete time stamp
  /// @param start is the start time of the plan
  /// @param cliffDate is the timestamp of the cliff of the plan
  /// @param amount is the total unclaimed amount tokens still in the vesting plan
  /// @param rate is the amount of tokens that unlock per period
  /// @param period is the seconds in each period, a 1 is a period of 1 second whereby tokens unlock every second
  /// @param currentTime is the current time being evaluated, typically the block.timestamp, but used just to check the plan is past the start or cliff
  /// @param redemptionTime is the time requested for the plan to be redeemed, this can be the same as the current time or prior to it for partial redemptions
  function balanceAtTime(
    uint256 start,
    uint256 cliffDate,
    uint256 amount,
    uint256 rate,
    uint256 period,
    uint256 currentTime,
    uint256 redemptionTime
  ) internal pure returns (uint256 unlockedBalance, uint256 lockedBalance, uint256 unlockTime) {
    if (start > currentTime || cliffDate > currentTime || redemptionTime <= start) {
      lockedBalance = amount;
      unlockTime = start;
    } else {
      uint256 periodsElapsed = (redemptionTime - start) / period;
      uint256 calculatedBalance = periodsElapsed * rate;
      unlockedBalance = min(calculatedBalance, amount);
      lockedBalance = amount - unlockedBalance;
      unlockTime = start + (period * periodsElapsed);
    }
  }

  function calculateCombinedRate(
    uint256 combinedAmount,
    uint256 combinedRates,
    uint256 start,
    uint256 period,
    uint256 targetEnd
  ) internal pure returns (uint256 rate, uint256 end) {
    uint256 numerator = combinedAmount * period;
    uint256 denominator = (combinedAmount % combinedRates == 0) ? targetEnd - start : targetEnd - start - period;
    rate = numerator / denominator;
    end = endDate(start, combinedAmount, rate, period);
  }

  function calculateSegmentRates(
    uint256 originalRate,
    uint256 originalAmount,
    uint256 planAmount,
    uint256 segmentAmount,
    uint256 start,
    uint256 end,
    uint256 period,
    uint256 cliff
  ) internal pure returns (uint256 planRate, uint256 segmentRate, uint256 planEnd, uint256 segmentEnd) {
    planRate = (originalRate * ((planAmount * (10 ** 18)) / originalAmount)) / (10 ** 18);
    segmentRate = (segmentAmount % (originalRate - planRate) == 0)
      ? (segmentAmount * period) / (end - start)
      : (segmentAmount * period) / (end - start - period);
    bool validPlanEnd;
    bool validSegmentEnd;
    (planEnd, validPlanEnd) = validateEnd(start, cliff, planAmount, planRate, period);
    (segmentEnd, validSegmentEnd) = validateEnd(start, cliff, segmentAmount, segmentRate, period);
    require(validPlanEnd && validSegmentEnd, 'invalid end date');
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';


/// @notice Library to help safely transfer tokens and handle ETH wrapping and unwrapping of WETH
library TransferHelper {
  using SafeERC20 for IERC20;

  /// @notice Internal function used for standard ERC20 transferFrom method
  /// @notice it contains a pre and post balance check
  /// @notice as well as a check on the msg.senders balance
  /// @param token is the address of the ERC20 being transferred
  /// @param from is the remitting address
  /// @param to is the location where they are being delivered
  function transferTokens(
    address token,
    address from,
    address to,
    uint256 amount
  ) internal {
    uint256 priorBalance = IERC20(token).balanceOf(address(to));
    require(IERC20(token).balanceOf(from) >= amount, 'THL01');
    SafeERC20.safeTransferFrom(IERC20(token), from, to, amount);
    uint256 postBalance = IERC20(token).balanceOf(address(to));
    require(postBalance - priorBalance == amount, 'THL02');
  }

  /// @notice Internal function is used with standard ERC20 transfer method
  /// @notice this function ensures that the amount received is the amount sent with pre and post balance checking
  /// @param token is the ERC20 contract address that is being transferred
  /// @param to is the address of the recipient
  /// @param amount is the amount of tokens that are being transferred
  function withdrawTokens(
    address token,
    address to,
    uint256 amount
  ) internal {
    uint256 priorBalance = IERC20(token).balanceOf(address(to));
    SafeERC20.safeTransfer(IERC20(token), to, amount);
    uint256 postBalance = IERC20(token).balanceOf(address(to));
    require(postBalance - priorBalance == amount, 'THL02');
  }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '../TokenLockupPlans.sol';

/// @title TokenLockupPlans_Bound - An efficient way to allocate tokens to beneficiaries that unlock over time
/// @notice This contract allows people to grant tokens to beneficiaries that unlock over time with the added functionalities;
/// Owners of unlock plans can manage all of their token unlocks across all of their positions in a single contract. 
/// Each lockup plan is a unique NFT, leveraging the backbone of the ERC721 contract to represent a unique lockup plan 
/// 1. Not-Revokable: plans cannot be revoked, once granted the entire amount will be claimable by the beneficiary over time. 
/// 2. Non-Transferable: Lockup plans are soul bound and cannot be transferred or participate in defi activities. 
/// 3. Governance optimized for snapshot voting: These are built to allow beneficiaries to vote with their locked tokens on snapshot, or delegate them to other delegatees
/// 4. Beneficiary Claims: Beneficiaries get to choose when to claim their tokens, and can claim partial amounts that are less than the amount they have unlocked for tax optimization
/// 5. Segmenting plans: Beneficiaries can segment a single lockup into  smaller chunks for subdelegation of tokens, or to use in defi with smaller chunks
/// 6. Combingin Plans: Beneficiaries can combine plans that have the same details in one larger chunk for easier bulk management

contract TokenLockupPlans_Bound is TokenLockupPlans {
  constructor(string memory name, string memory symbol) TokenLockupPlans(name, symbol) {}

  /// @notice this function overrides the internal transfer function so that these plans and tokens cannot be transferred
  /// we check that the from address is not 0, which would indicate a mint, or that the to address is not 0, which would be a burn
  /// if neither address is the 0x0, then it is a transfer between wallets and is not allowable
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    if (from != address(0) && to != address(0)) revert('Not Transferable');
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '../VotingTokenLockupPlans.sol';

/// @title VotingTokenLockupPlans_Bound - An efficient way to allocate tokens to beneficiaries that unlock over time
/// @notice This contract allows people to grant tokens to beneficiaries that unlock over time with the added functionalities;
/// Owners of unlock plans can manage all of their token unlocks across all of their positions in a single contract. 
/// Each lockup plan is a unique NFT, leveraging the backbone of the ERC721 contract to represent a unique lockup plan 
/// 1. Not-Revokable: plans cannot be revoked, once granted the entire amount will be claimable by the beneficiary over time. 
/// 2. Non-Transferable: Lockup plans are soul bound and cannot be transferred or participate in defi activities.  
/// 3. Governance optimized for on-chain voting: These are built to allow beneficiaries to vote with their unvested tokens on chain with the standard ERC20Votes contract, as well as on snapshot
/// 4. Beneficiary Claims: Beneficiaries get to choose when to claim their tokens, and can claim partial amounts that are less than the amount they have unlocked for tax optimization
/// 5. Segmenting plans: Beneficiaries can segment a single lockup into  smaller chunks for subdelegation of tokens, or to use in defi with smaller chunks
/// 6. Combingin Plans: Beneficiaries can combine plans that have the same details in one larger chunk for easier bulk management

contract VotingTokenLockupPlans_Bound is VotingTokenLockupPlans {
  constructor(string memory name, string memory symbol) VotingTokenLockupPlans(name, symbol) {}
  
  /// @notice this function overrides the internal transfer function so that these plans and tokens cannot be transferred
  /// we check that the from address is not 0, which would indicate a mint, or that the to address is not 0, which would be a burn
  /// if neither address is the 0x0, then it is a transfer between wallets and is not allowable
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    if (from != address(0) && to != address(0)) revert('Not Transferable');
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '../ERC721Delegate/ERC721Delegate.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../libraries/TransferHelper.sol';
import '../libraries/TimelockLibrary.sol';
import '../sharedContracts/URIAdmin.sol';
import '../sharedContracts/LockupStorage.sol';

/// @title TokenLockupPlans - An efficient way to allocate tokens to beneficiaries that unlock over time
/// @notice This contract allows people to grant tokens to beneficiaries that unlock over time with the added functionalities;
/// Owners of unlock plans can manage all of their token unlocks across all of their positions in a single contract.
/// Each lockup plan is a unique NFT, leveraging the backbone of the ERC721 contract to represent a unique lockup plan
/// 1. Not-Revokable: plans cannot be revoked, once granted the entire amount will be claimable by the beneficiary over time.
/// 2. Transferable: Lockup plans can be transferred by the owner - opening up defi opportunities like NFT sales, borrowing and lending, and many others.
/// 3. Governance optimized for snapshot voting: These are built to allow beneficiaries to vote with their locked tokens on snapshot, or delegate them to other delegatees
/// 4. Beneficiary Claims: Beneficiaries get to choose when to claim their tokens, and can claim partial amounts that are less than the amount they have unlocked for tax optimization
/// 5. Segmenting plans: Beneficiaries can segment a single lockup into  smaller chunks for subdelegation of tokens, or to use in defi with smaller chunks
/// 6. Combingin Plans: Beneficiaries can combine plans that have the same details in one larger chunk for easier bulk management

contract TokenLockupPlans is ERC721Delegate, LockupStorage, ReentrancyGuard, URIAdmin {
  /// @notice uses counters for incrementing token IDs which are the planIds
  using Counters for Counters.Counter;
  Counters.Counter private _planIds;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    uriAdmin = msg.sender;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /****CORE EXTERNAL FUNCTIONS*********************************************************************************************************************************************/
  /// @notice function to create a lockup plan.
  /// @dev this function will pull the tokens into this contract for escrow, increment the planIds, mint an NFT to the recipient, and create the storage Plan and map it to the newly minted NFT token ID in storage
  /// @param recipient the address of the recipient and beneficiary of the plan
  /// @param token the address of the ERC20 token
  /// @param amount the amount of tokens to be locked in the plan
  /// @param start the start date of the lockup plan, unix time
  /// @param cliff a cliff date which is a discrete date where tokens are not unlocked until this date, and then vest in a large single chunk on the cliff date
  /// @param rate the amount of tokens that vest in a single period
  /// @param period the amount of time in between each unlock time stamp, in seconds. A period of 1 means that tokens vest every second in a 'streaming' style.
  function createPlan(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 rate,
    uint256 period
  ) external nonReentrant returns (uint256 newPlanId) {
    require(recipient != address(0), '0_recipient');
    require(token != address(0), '0_token');
    (uint256 end, bool valid) = TimelockLibrary.validateEnd(start, cliff, amount, rate, period);
    require(valid);
    _planIds.increment();
    newPlanId = _planIds.current();
    TransferHelper.transferTokens(token, msg.sender, address(this), amount);
    plans[newPlanId] = Plan(token, amount, start, cliff, rate, period);
    _safeMint(recipient, newPlanId);
    emit PlanCreated(newPlanId, recipient, token, amount, start, cliff, end, rate, period);
  }

  /// @notice function for a beneficiary to redeem unlocked tokens from a group of plans
  /// @dev this will call an internal function for processing the actual redemption of tokens, which will withdraw unlocked tokens and deliver them to the beneficiary
  /// @dev this function will redeem all claimable and unlocked tokens up to the current block.timestamp
  /// @param planIds is the array of the NFT planIds that are to be redeemed. If any have no redeemable balance they will be skipped.
  function redeemPlans(uint256[] calldata planIds) external nonReentrant {
    _redeemPlans(planIds, block.timestamp);
  }

  /// @notice function for a beneficiary to redeem unlocked tokens from a group of plans
  /// @dev this will call an internal function for processing the actual redemption of tokens, which will withdraw unlocked tokens and deliver them to the beneficiary
  /// @dev this function will redeem only a partial amount of tokens based on a redemption timestamp that is in the past. This allows holders to redeem less than their fully unlocked amount for various reasons
  /// @param planIds is the array of the NFT planIds that are to be redeemed. If any have no redeemable balance they will be skipped.
  /// @param redemptionTime is the timestamp which will calculate the amount of tokens redeemable and redeem them based on that timestamp
  function partialRedeemPlans(uint256[] calldata planIds, uint256 redemptionTime) external nonReentrant {
    require(redemptionTime < block.timestamp, '!future');
    _redeemPlans(planIds, redemptionTime);
  }

  /// @notice this function will redeem all plans owned by a single wallet - useful for custodians or other intermeidaries that do not have the ability to lookup individual planIds
  /// @dev this will iterate through all of the plans owned by the wallet based on the ERC721Enumerable backbone, and redeem each one with a redemption time of the current block.timestamp
  function redeemAllPlans() external nonReentrant {
    uint256 balance = balanceOf(msg.sender);
    uint256[] memory planIds = new uint256[](balance);
    for (uint256 i; i < balance; i++) {
      uint256 planId = tokenOfOwnerByIndex(msg.sender, i);
      planIds[i] = planId;
    }
    _redeemPlans(planIds, block.timestamp);
  }

  /// @notice function for an owner of a lockup plan to segment a single plan into multiple chunks; segments.
  /// @dev the single plan can be divided up into many segments in this transaction, but care must be taken to ensure that the array is processed in a proper order
  /// if the tokens are send in the wrong order the function will revert becuase the amount of the segment could be larger than the original plan.
  /// this function iterates through the segment amounts and breaks up the same original plan into smaller sizes
  /// each time a segment happens it is always with the single planId, which will generate a new NFT for each new segment, and the original plan is updated in storage
  /// the original plan amount newPlanAmount + segmentAmount && original plan Rate = newPlanRate + segmentRate
  /// @dev Segmenting plans where the segment amount is not divisible by the rate will result in a new End date that is 1 period farther than the original plan
  /// @param planId is the plan that is going to be segmented
  /// @param segmentAmounts is the array of amounts of each individual segment, which must each be smaller than the plan when it is being segmented.
  function segmentPlan(
    uint256 planId,
    uint256[] memory segmentAmounts
  ) external nonReentrant returns (uint256[] memory newPlanIds) {
    newPlanIds = new uint256[](segmentAmounts.length);
    for (uint256 i; i < segmentAmounts.length; i++) {
      uint256 newPlanId = _segmentPlan(planId, segmentAmounts[i]);
      newPlanIds[i] = newPlanId;
    }
  }

  /// @notice this function combines the functionality of segmenting plans and then immediately delegating the new semgent plans to a delegate address
  /// @dev this function does NOT delegate the original planId at all, it will only delegate the newly create segments
  /// @param planId is the plan that will be segmented (and not delegated)
  /// @param segmentAmounts is the array of each segment amount
  /// @param delegatees is the array of delegatees that each new segment will be delegated to
  function segmentAndDelegatePlans(
    uint256 planId,
    uint256[] memory segmentAmounts,
    address[] memory delegatees
  ) external nonReentrant returns (uint256[] memory newPlanIds) {
    require(segmentAmounts.length == delegatees.length, 'length_error');
    newPlanIds = new uint256[](segmentAmounts.length);
    for (uint256 i; i < segmentAmounts.length; i++) {
      uint256 newPlanId = _segmentPlan(planId, segmentAmounts[i]);
      _delegateToken(delegatees[i], newPlanId);
      newPlanIds[i] = newPlanId;
    }
  }

  /// @notice this function allows a beneficiary of two plans that share the same details to combine them into a single surviving plan
  /// @dev the plans must have the same details except the amount and rate, but must share the same end date to be combined
  /// @param planId0 is the planId of a first plan to be combined
  /// @param planId1 is the planId of a second plan to be combined
  function combinePlans(uint256 planId0, uint256 planId1) external nonReentrant returns (uint256 survivingPlanId) {
    survivingPlanId = _combinePlans(planId0, planId1);
  }

  /****EXTERNAL VOTING & DELEGATION FUNCTIONS*********************************************************************************************************************************************/
  /// @notice delegation functions do not move any tokens and do not alter any information about the lockup plan object.
  /// the specifically delegate the NFTs using the ERC721Delegate.sol extension.
  /// Use the dedicated snapshot strategy 'hedgey-delegate' to leverage the delegation functions for voting with snapshot

  /// @notice function to delegate an individual NFT tokenId to another wallet address.
  /// @dev by default all plans are self delegated, this allows for the owner of a plan to delegate their NFT to a different address.
  /// This calls the internal _delegateToken function from ERC721Delegate.sol contract
  /// @param planId is the token Id of the NFT and lockup plan to be delegated
  /// @param delegatee is the address that the plan will be delegated to
  function delegate(uint256 planId, address delegatee) external nonReentrant {
    _delegateToken(delegatee, planId);
  }

  /// @notice functeion to delegate multiple plans to multiple delegates in a single transaction
  /// @dev this also calls the internal _delegateToken function from ERC721Delegate.sol to delegate an NFT to another wallet.
  /// @dev this function iterates through the array of plans and delegatees, delegating each individual NFT.
  /// @param planIds is the array of planIds that will be delegated
  /// @param delegatees is the array of addresses that each corresponding planId will be delegated to
  function delegatePlans(uint256[] calldata planIds, address[] calldata delegatees) external nonReentrant {
    require(planIds.length == delegatees.length, 'array error');
    for (uint256 i; i < planIds.length; i++) {
      _delegateToken(delegatees[i], planIds[i]);
    }
  }

  /// @notice function to delegate all plans related to a specific token to a single delegatee address
  /// @dev this function pulls the balances of a wallet, checks that the token in the lockup plan matches the token input param, and then delegates it to the delegatee
  /// @param token is the address of the ERC20 tokens that are locked in the lockup plans desired to be delegated
  /// @param delegatee is the address of the delegate that all of the NFTs / plans will be delegated to.
  function delegateAll(address token, address delegatee) external nonReentrant {
    uint256 balance = balanceOf(msg.sender);
    for (uint256 i; i < balance; i++) {
      uint256 planId = tokenOfOwnerByIndex(msg.sender, i);
      if (plans[planId].token == token) _delegateToken(delegatee, planId);
    }
  }

  function transferAndDelegate(uint256 planId, address from, address to) external virtual nonReentrant {
    safeTransferFrom(from, to, planId);
    _transferDelegate(to, planId);
  }

  /****CORE INTERNAL FUNCTIONS*********************************************************************************************************************************************/

  /// @notice function that will intake an array of planIds and a redemption time, and then check the balances that are available to be redeemed
  /// @dev if the nft has an available balance, it is then passed on to the _redeemPlan function for further processing
  /// if there is no balance to be redeemed, the plan is skipped from being processed
  /// @param planIds is the array of plans to be redeemed
  /// @param redemptionTime is the requested redemption time, either the current block.timestamp or a timestamp from the past, but must be greater than the start date
  function _redeemPlans(uint256[] memory planIds, uint256 redemptionTime) internal {
    for (uint256 i; i < planIds.length; i++) {
      (uint256 balance, uint256 remainder, uint256 latestUnlock) = planBalanceOf(
        planIds[i],
        block.timestamp,
        redemptionTime
      );
      if (balance > 0) _redeemPlan(planIds[i], balance, remainder, latestUnlock);
    }
  }

  /// @notice internal function that process the redemption for a single lockup plan
  /// @dev this takes the inputs from the _redeemPlans and processes the redemption delivering the available balance of redeemable tokens to the beneficiary
  /// if the plan is fully redeemed, as defined that the balance == amount, then the plan is deleted and NFT burned
  // if the plan is not fully redeemed, then the storage of start and amount are updated to reflect the remaining amount and most recent time redeemed for the new start date
  /// @param planId is the id of the lockup plan and NFT
  /// @param balance is the available redeemable balance
  /// @param remainder is the amount of tokens that are still lcoked in the plan, and will be the new amount in the plan storage
  /// @param latestUnlock is the most recent timestamp for when redemption occured. Because periods may be longer than 1 second,
  /// the latestUnlock time may be the current block time, or the timestamp of the most recent period timestamp
  function _redeemPlan(uint256 planId, uint256 balance, uint256 remainder, uint256 latestUnlock) internal {
    require(ownerOf(planId) == msg.sender, '!owner');
    address token = plans[planId].token;
    if (remainder == 0) {
      delete plans[planId];
      _burn(planId);
    } else {
      plans[planId].amount = remainder;
      plans[planId].start = latestUnlock;
    }
    TransferHelper.withdrawTokens(token, msg.sender, balance);
    emit PlanRedeemed(planId, balance, remainder, latestUnlock);
  }

  /// @notice the internal function for segmenting a single plan into two
  /// @dev the function takes a plan, performs some checks that the segment amount cannot be 0 and must be strictly less than the original plan amount
  /// then it will subtract the segmentamount from the original plan amount to get the new plan amount
  /// then it will get a new pro-rata rate for the newplan based on the new plan amount divided by the original plan amount
  /// while this pro-rata new rate is not perfect because of unitization (ie no decimal suppport), the segment rate is calculated by subtracting the new plan rate from the original plan rate
  /// because the newplan amount and segment amount == original plan amount, and the new plan rate + segment rate == original plan rate, the beneficiary will still unlock the same number of tokens at approximatley the same rate
  /// however because of uneven division, the end dates of each of the new rates may be different than the original rate. We check to make sure that the new end is farther than the original end
  /// so that tokens do not unlock early, and then it is a valid segment.
  /// finally a new NFT is minted with the Segment plan details
  /// and the storage of the original plan amount and rate is updated with the newplan amount and rate.
  /// @param planId is the id of the lockup plan
  /// @param segmentAmount is the amount of tokens to be segmented off from the original plan and created into a new segment plan
  function _segmentPlan(uint256 planId, uint256 segmentAmount) internal returns (uint256 newPlanId) {
    require(ownerOf(planId) == msg.sender, '!owner');
    Plan memory plan = plans[planId];
    require(segmentAmount < plan.amount, 'amount error');
    require(segmentAmount > 0, '0_segment');
    uint256 end = TimelockLibrary.endDate(plan.start, plan.amount, plan.rate, plan.period);
    _planIds.increment();
    newPlanId = _planIds.current();
    uint256 planAmount = plan.amount - segmentAmount;
    (uint256 planRate, uint256 segmentRate, uint256 planEnd, uint256 segmentEnd) = TimelockLibrary
      .calculateSegmentRates(
        plan.rate,
        plan.amount,
        planAmount,
        segmentAmount,
        plan.start,
        end,
        plan.period,
        plan.cliff
      );
    uint256 endCheck = segmentOriginalEnd[planId] == 0 ? end : segmentOriginalEnd[planId];
    require(planEnd >= endCheck, 'plan end error');
    require(segmentEnd >= endCheck, 'segmentEnd error');
    plans[planId].amount = planAmount;
    plans[planId].rate = planRate;
    _safeMint(msg.sender, newPlanId);
    plans[newPlanId] = Plan(plan.token, segmentAmount, plan.start, plan.cliff, segmentRate, plan.period);
    if (segmentOriginalEnd[planId] == 0) {
      segmentOriginalEnd[planId] = end;
      segmentOriginalEnd[newPlanId] = end;
    } else {
      segmentOriginalEnd[newPlanId] = segmentOriginalEnd[planId];
    }
    emit PlanSegmented(
      planId,
      newPlanId,
      planAmount,
      planRate,
      segmentAmount,
      segmentRate,
      plan.start,
      plan.cliff,
      plan.period,
      planEnd,
      segmentEnd
    );
  }

  /// @notice this funtion allows the holder of two plans that have the same parameters to combine them into a single surviving plan
  /// @dev all of the details of the plans must be the same except the amounts and rates may be different
  /// this function will check that the owners are the same, the ERC20 tokens are the same, the start, cliff and periods are the same.
  /// then it performs some checks on the end dates to ensure that either the end dates are the same, or if the user is combining previously segmented plans,
  /// that the original end dates of those segments are the same.
  /// if everything checks out, and the new end date of the combined plan will result in an end date equal to or later than the two plans, then they can be combined
  /// combining plans will delete the plan1 and burn the NFT related to it
  /// and then update the storage of the plan0 with the combined amount and combined rate
  /// @param planId0 is the planId of the first plan in the combination
  /// @param planId1 is the planId of a second plan to be combined
  function _combinePlans(uint256 planId0, uint256 planId1) internal returns (uint256 survivingPlan) {
    require(ownerOf(planId0) == msg.sender, '!owner');
    require(ownerOf(planId1) == msg.sender, '!owner');
    Plan memory plan0 = plans[planId0];
    Plan memory plan1 = plans[planId1];
    require(plan0.token == plan1.token, 'token error');
    require(plan0.start == plan1.start, 'start error');
    require(plan0.cliff == plan1.cliff, 'cliff error');
    require(plan0.period == plan1.period, 'period error');
    uint256 plan0End = TimelockLibrary.endDate(plan0.start, plan0.amount, plan0.rate, plan0.period);
    uint256 plan1End = TimelockLibrary.endDate(plan1.start, plan1.amount, plan1.rate, plan1.period);
    require(
      plan0End == plan1End ||
        (segmentOriginalEnd[planId0] == segmentOriginalEnd[planId1] && segmentOriginalEnd[planId0] != 0),
      'end error'
    );
    plans[planId0].amount += plans[planId1].amount;
    (uint256 survivorRate, uint256 survivorEnd) = TimelockLibrary.calculateCombinedRate(
      plan0.amount + plan1.amount,
      plan0.rate + plan1.rate,
      plan0.start,
      plan0.period,
      plan0End
    );
    plans[planId0].rate = survivorRate;
    if (survivorEnd < plan0End) {
      require(
        survivorEnd == segmentOriginalEnd[planId0] || survivorEnd == segmentOriginalEnd[planId1],
        'original end error'
      );
    }
    delete plans[planId1];
    _burn(planId1);
    survivingPlan = planId0;
    emit PlansCombined(
      planId0,
      planId1,
      survivingPlan,
      plans[planId0].amount,
      survivorRate,
      plan0.start,
      plan0.cliff,
      plan0.period,
      survivorEnd
    );
  }

  /****VIEW VOTING FUNCTIONS*********************************************************************************************************************************************/

  /// @notice this function will pull all of the unclaimed tokens for a specific holder across all of their plans, based on a single ERC20 token
  /// very useful for snapshot voting, and other view functionalities
  /// @param holder is the address of the beneficiary who owns the lockup plan(s)
  /// @param token is the ERC20 address of the token that is stored across the lockup plans
  function lockedBalances(address holder, address token) external view returns (uint256 lockedBalance) {
    uint256 holdersBalance = balanceOf(holder);
    for (uint256 i; i < holdersBalance; i++) {
      uint256 planId = tokenOfOwnerByIndex(holder, i);
      Plan memory plan = plans[planId];
      if (token == plan.token) {
        lockedBalance += plan.amount;
      }
    }
  }

  /// @notice this function will pull all of the tokens locked in lockup plans for a specific delegate
  /// this is useful for the snapshot strategy hedgey-delegate, polling this function based on the wallet signed into snapshot
  /// by default all NFTs are self-delegated when they are minted.
  /// @param delegatee is the address of the delegate where NFTs have been delegated to
  /// @param token is the address of the ERC20 token that is locked in lockup plans and has been delegated
  function delegatedBalances(address delegatee, address token) external view returns (uint256 delegatedBalance) {
    uint256 delegateBalance = balanceOfDelegate(delegatee);
    for (uint256 i; i < delegateBalance; i++) {
      uint256 planId = tokenOfDelegateByIndex(delegatee, i);
      Plan memory plan = plans[planId];
      if (token == plan.token) {
        delegatedBalance += plan.amount;
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '../sharedContracts/PlanDelegator.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../libraries/TransferHelper.sol';
import '../libraries/TimelockLibrary.sol';
import '../sharedContracts/VotingVault.sol';
import '../sharedContracts/URIAdmin.sol';
import '../sharedContracts/LockupStorage.sol';

/// @title TokenLockupPlans - An efficient way to allocate tokens to beneficiaries that unlock over time
/// @notice This contract allows people to grant tokens to beneficiaries that unlock over time with the added functionalities;
/// Owners of unlock plans can manage all of their token unlocks across all of their positions in a single contract.
/// Each lockup plan is a unique NFT, leveraging the backbone of the ERC721 contract to represent a unique lockup plan
/// 1. Not-Revokable: plans cannot be revoked, once granted the entire amount will be claimable by the beneficiary over time.
/// 2. Transferable: Lockup plans can be transferred by the owner - opening up defi opportunities like NFT sales, borrowing and lending, and many others.
/// 3. Governance optimized for on-chain voting: These are built to allow beneficiaries to vote with their unvested tokens on chain with the standard ERC20Votes contract, as well as on snapshot
/// 4. Beneficiary Claims: Beneficiaries get to choose when to claim their tokens, and can claim partial amounts that are less than the amount they have unlocked for tax optimization
/// 5. Segmenting plans: Beneficiaries can segment a single lockup into  smaller chunks for subdelegation of tokens, or to use in defi with smaller chunks
/// 6. Combingin Plans: Beneficiaries can combine plans that have the same details in one larger chunk for easier bulk management
contract VotingTokenLockupPlans is PlanDelegator, LockupStorage, ReentrancyGuard, URIAdmin {
  /// @notice uses counters for incrementing token IDs which are the planIds
  using Counters for Counters.Counter;
  Counters.Counter private _planIds;

  /// @dev Voting Vaults are external contracts that hold tokens for a lockup plan allowing an owner to delegate their tokens for on-chain governance
  /// the lockup plan ID is mapped to the votingVault address so that it is one to one and unique to the NFT
  mapping(uint256 => address) public votingVaults;

  /// @notice event emitted when a new voting vault is generated and setup
  event VotingVaultCreated(uint256 indexed id, address vaultAddress);

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    uriAdmin = msg.sender;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /****CORE EXTERNAL FUNCTIONS*********************************************************************************************************************************************/

  /// @notice function to create a lockup plan.
  /// @dev this function will pull the tokens into this contract for escrow, increment the planIds, mint an NFT to the recipient, and create the storage Plan and map it to the newly minted NFT token ID in storage
  /// @param recipient the address of the recipient and beneficiary of the plan
  /// @param token the address of the ERC20 token
  /// @param amount the amount of tokens to be locked in the plan
  /// @param start the start date of the lockup plan, unix time
  /// @param cliff a cliff date which is a discrete date where tokens are not unlocked until this date, and then vest in a large single chunk on the cliff date
  /// @param rate the amount of tokens that vest in a single period
  /// @param period the amount of time in between each unlock time stamp, in seconds. A period of 1 means that tokens vest every second in a 'streaming' style.
  function createPlan(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 rate,
    uint256 period
  ) external nonReentrant returns (uint256 newPlanId) {
    require(recipient != address(0), '0_recipient');
    require(token != address(0), '0_token');
    (uint256 end, bool valid) = TimelockLibrary.validateEnd(start, cliff, amount, rate, period);
    require(valid);
    _planIds.increment();
    newPlanId = _planIds.current();
    TransferHelper.transferTokens(token, msg.sender, address(this), amount);
    plans[newPlanId] = Plan(token, amount, start, cliff, rate, period);
    _safeMint(recipient, newPlanId);
    emit PlanCreated(newPlanId, recipient, token, amount, start, cliff, end, rate, period);
  }

  /// @notice function for a beneficiary to redeem unlocked tokens from a group of plans
  /// @dev this will call an internal function for processing the actual redemption of tokens, which will withdraw unlocked tokens and deliver them to the beneficiary
  /// @dev this function will redeem all claimable and unlocked tokens up to the current block.timestamp
  /// @param planIds is the array of the NFT planIds that are to be redeemed. If any have no redeemable balance they will be skipped.
  function redeemPlans(uint256[] calldata planIds) external nonReentrant {
    _redeemPlans(planIds, block.timestamp);
  }

  /// @notice function for a beneficiary to redeem unlocked tokens from a group of plans
  /// @dev this will call an internal function for processing the actual redemption of tokens, which will withdraw unlocked tokens and deliver them to the beneficiary
  /// @dev this function will redeem only a partial amount of tokens based on a redemption timestamp that is in the past. This allows holders to redeem less than their fully unlocked amount for various reasons
  /// @param planIds is the array of the NFT planIds that are to be redeemed. If any have no redeemable balance they will be skipped.
  /// @param redemptionTime is the timestamp which will calculate the amount of tokens redeemable and redeem them based on that timestamp
  function partialRedeemPlans(uint256[] calldata planIds, uint256 redemptionTime) external nonReentrant {
    require(redemptionTime < block.timestamp, '!future');
    _redeemPlans(planIds, redemptionTime);
  }

  /// @notice this function will redeem all plans owned by a single wallet - useful for custodians or other intermeidaries that do not have the ability to lookup individual planIds
  /// @dev this will iterate through all of the plans owned by the wallet based on the ERC721Enumerable backbone, and redeem each one with a redemption time of the current block.timestamp
  function redeemAllPlans() external nonReentrant {
    uint256 balance = balanceOf(msg.sender);
    uint256[] memory planIds = new uint256[](balance);
    for (uint256 i; i < balance; i++) {
      uint256 planId = tokenOfOwnerByIndex(msg.sender, i);
      planIds[i] = planId;
    }
    _redeemPlans(planIds, block.timestamp);
  }

  /// @notice function for an owner of a lockup plan to segment a single plan into multiple chunks; segments.
  /// @dev the single plan can be divided up into many segments in this transaction, but care must be taken to ensure that the array is processed in a proper order
  /// if the tokens are send in the wrong order the function will revert becuase the amount of the segment could be larger than the original plan.
  /// this function iterates through the segment amounts and breaks up the same original plan into smaller sizes
  /// each time a segment happens it is always with the single planId, which will generate a new NFT for each new segment, and the original plan is updated in storage
  /// the original plan amount newPlanAmount + segmentAmount && original plan Rate = newPlanRate + segmentRate
  /// IF The plan that is being segmented has a voting vault setup, it will generate a new voting vault for the segmented tokens, however it will not delegate those
  /// @dev Segmenting plans where the segment amount is not divisible by the rate will result in a new End date that is 1 period farther than the original plan
  /// @param planId is the plan that is going to be segmented
  /// @param segmentAmounts is the array of amounts of each individual segment, which must each be smaller than the plan when it is being segmented.
  function segmentPlan(
    uint256 planId,
    uint256[] memory segmentAmounts
  ) external nonReentrant returns (uint256[] memory newPlanIds) {
    newPlanIds = new uint256[](segmentAmounts.length);
    for (uint256 i; i < segmentAmounts.length; i++) {
      uint256 newPlanId = _segmentPlan(planId, segmentAmounts[i]);
      newPlanIds[i] = newPlanId;
    }
  }

  /// @notice this function combines the functionality of segmenting plans and then immediately delegating the new semgent plans to a delegate address
  /// @dev this function does NOT delegate the original planId at all, it will only delegate the newly create segments
  /// if the plan has a Voting Vault, it will create a new voting vault for each segment, and then delegate the tokens in the voting vault to the delegatee address
  /// @param planId is the plan that will be segmented (and not delegated)
  /// @param segmentAmounts is the array of each segment amount
  /// @param delegatees is the array of delegatees that each new segment will be delegated to
  function segmentAndDelegatePlans(
    uint256 planId,
    uint256[] memory segmentAmounts,
    address[] memory delegatees
  ) external nonReentrant returns (uint256[] memory newPlanIds) {
    require(segmentAmounts.length == delegatees.length, '!length');
    newPlanIds = new uint256[](segmentAmounts.length);
    for (uint256 i; i < segmentAmounts.length; i++) {
      uint256 newPlanId = _segmentPlan(planId, segmentAmounts[i]);
      _delegate(newPlanId, delegatees[i]);
      newPlanIds[i] = newPlanId;
    }
  }

  /// @notice this function allows a beneficiary of two plans that share the same details to combine them into a single surviving plan
  /// @dev the plans must have the same details except the amount and rate, but must share the same end date to be combined
  /// if one of the plans has a voting vault, that plan will be the surviving plan and all tokens will be transferred to the surviving plan voting vault
  /// @param planId0 is the planId of a first plan to be combined
  /// @param planId1 is the planId of a second plan to be combined
  function combinePlans(uint256 planId0, uint256 planId1) external nonReentrant returns (uint256 survivingPlanId) {
    survivingPlanId = _combinePlans(planId0, planId1);
  }

  /****EXTERNAL VOTING FUNCTIONS*********************************************************************************************************************************************/
  /// @notice functions for the owners of lockup plans to setup on chain voting vaults, and then delegate those tokens.
  /// these are explicity for tokens that are of the ERC20Votes format, which have a delegate and delegates function.
  /// tokens that do not have the standard delegate and delegates functionality for on-chain voting will revert when delegating or creating onchain voting vaults.

  /// @notice function to setup a voting vault, this calls an internal voting function to set it up
  // this will physically transfer tokens to the new voting vault contract once deployed
  /// @param planId is the id of the lockup plan and NFT
  function setupVoting(uint256 planId) external nonReentrant returns (address votingVault) {
    votingVault = _setupVoting(planId);
  }

  /// @notice function for an owner of a lockup plan to delegate a single lockup plan to  single delegate
  /// @dev this will call an internal delegate function for processing
  /// if there is no voting vault setup, this function will automatically create a voting vault and then delegate the tokens to the delegatee
  /// @param planId is the id of the lockup plan and NFT
  function delegate(uint256 planId, address delegatee) external nonReentrant {
    _delegate(planId, delegatee);
  }

  /// @notice this function allows an owner of multiple lockup plans to delegate multiple of them in a single transaction, each planId corresponding to a delegatee address
  /// @param planIds is the ids of the lockup plan and NFT
  /// @param delegatees is the array of addresses where each lockup plan will delegate the tokens to
  function delegatePlans(uint256[] calldata planIds, address[] calldata delegatees) external nonReentrant {
    require(planIds.length == delegatees.length, 'array error');
    for (uint256 i; i < planIds.length; i++) {
      _delegate(planIds[i], delegatees[i]);
    }
  }

  /// @notice this function lets an owner delegate all of their lockup plans for a single token to a single delegatee
  /// @dev this function will iterate through all of the owned lockup plans of the msg.sender, and if the token address matches the lockup plan token address, it will delegate that plan
  /// @param token is the ERC20Votes token address of the tokens in the lockup plans
  /// @param delegatee is the address of the delegate that the beneficiary is delegating their tokens to
  function delegateAll(address token, address delegatee) external nonReentrant {
    uint256 balance = balanceOf(msg.sender);
    for (uint256 i; i < balance; i++) {
      uint256 planId = tokenOfOwnerByIndex(msg.sender, i);
      if (plans[planId].token == token) _delegate(planId, delegatee);
    }
  }

  function transferAndDelegate(uint256 planId, address from, address to) external virtual nonReentrant {
    safeTransferFrom(from, to, planId);
    _delegate(planId, to);
  }

  /****CORE INTERNAL FUNCTIONS*********************************************************************************************************************************************/

  /// @notice function that will intake an array of planIds and a redemption time, and then check the balances that are available to be redeemed
  /// @dev if the nft has an available balance, it is then passed on to the _redeemPlan function for further processing
  /// if there is no balance to be redeemed, the plan is skipped from being processed
  /// @param planIds is the array of plans to be redeemed
  /// @param redemptionTime is the requested redemption time, either the current block.timestamp or a timestamp from the past, but must be greater than the start date
  function _redeemPlans(uint256[] memory planIds, uint256 redemptionTime) internal {
    for (uint256 i; i < planIds.length; i++) {
      (uint256 balance, uint256 remainder, uint256 latestUnlock) = planBalanceOf(
        planIds[i],
        block.timestamp,
        redemptionTime
      );
      if (balance > 0) _redeemPlan(planIds[i], balance, remainder, latestUnlock);
    }
  }

  /// @notice internal function that process the redemption for a single lockup plan
  /// @dev this takes the inputs from the _redeemPlans and processes the redemption delivering the available balance of redeemable tokens to the beneficiary
  /// if the plan has a voting vault then tokens will be redeemed and transferred from the voting vault to the beneficiary.
  /// if the plan is fully redeemed, as defined that the balance == amount, then the plan is deleted and NFT burned
  // if the plan is not fully redeemed, then the storage of start and amount are updated to reflect the remaining amount and most recent time redeemed for the new start date
  /// @param planId is the id of the lockup plan and NFT
  /// @param balance is the available redeemable balance
  /// @param remainder is the amount of tokens that are still lcoked in the plan, and will be the new amount in the plan storage
  /// @param latestUnlock is the most recent timestamp for when redemption occured. Because periods may be longer than 1 second,
  /// the latestUnlock time may be the current block time, or the timestamp of the most recent period timestamp
  function _redeemPlan(uint256 planId, uint256 balance, uint256 remainder, uint256 latestUnlock) internal {
    require(ownerOf(planId) == msg.sender, '!owner');
    address token = plans[planId].token;
    address vault = votingVaults[planId];
    if (remainder == 0) {
      delete plans[planId];
      delete votingVaults[planId];
      _burn(planId);
    } else {
      plans[planId].amount = remainder;
      plans[planId].start = latestUnlock;
    }
    if (vault == address(0)) {
      TransferHelper.withdrawTokens(token, msg.sender, balance);
    } else {
      VotingVault(vault).withdrawTokens(msg.sender, balance);
    }
    emit PlanRedeemed(planId, balance, remainder, latestUnlock);
  }

  /// @notice the internal function for segmenting a single plan into two
  /// @dev the function takes a plan, performs some checks that the segment amount cannot be 0 and must be strictly less than the original plan amount
  /// then it will subtract the segmentamount from the original plan amount to get the new plan amount
  /// then it will get a new pro-rata rate for the newplan based on the new plan amount divided by the original plan amount
  /// while this pro-rata new rate is not perfect because of unitization (ie no decimal suppport), the segment rate is calculated by subtracting the new plan rate from the original plan rate
  /// because the newplan amount and segment amount == original plan amount, and the new plan rate + segment rate == original plan rate, the beneficiary will still unlock the same number of tokens at approximatley the same rate
  /// however because of uneven division, the end dates of each of the new rates may be different than the original rate. We check to make sure that the new end is farther than the original end
  /// so that tokens do not unlock early, and then it is a valid segment.
  /// finally a new NFT is minted with the Segment plan details
  /// and the storage of the original plan amount and rate is updated with the newplan amount and rate.
  /// at the end this checks if there is a voting vault setup for the original plan. If there is a voting vault setup, it will transfer tokens back from the original plan vault,
  /// then setup a new voting vault for the segment plan, thereby transferring the segment tokens to the new segment voting vault
  /// @param planId is the id of the lockup plan
  /// @param segmentAmount is the amount of tokens to be segmented off from the original plan and created into a new segment plan
  function _segmentPlan(uint256 planId, uint256 segmentAmount) internal returns (uint256 newPlanId) {
    require(ownerOf(planId) == msg.sender, '!owner');
    Plan memory plan = plans[planId];
    require(segmentAmount < plan.amount, 'amount error');
    require(segmentAmount > 0, '0_segment');
    uint256 end = TimelockLibrary.endDate(plan.start, plan.amount, plan.rate, plan.period);
    _planIds.increment();
    newPlanId = _planIds.current();
    uint256 planAmount = plan.amount - segmentAmount;
    (uint256 planRate, uint256 segmentRate, uint256 planEnd, uint256 segmentEnd) = TimelockLibrary
      .calculateSegmentRates(
        plan.rate,
        plan.amount,
        planAmount,
        segmentAmount,
        plan.start,
        end,
        plan.period,
        plan.cliff
      );
    uint256 endCheck = segmentOriginalEnd[planId] == 0 ? end : segmentOriginalEnd[planId];
    require(planEnd >= endCheck, 'plan end error');
    require(segmentEnd >= endCheck, 'segmentEnd error');
    plans[planId].amount = planAmount;
    plans[planId].rate = planRate;
    _safeMint(msg.sender, newPlanId);
    plans[newPlanId] = Plan(plan.token, segmentAmount, plan.start, plan.cliff, segmentRate, plan.period);
    if (segmentOriginalEnd[planId] == 0) {
      segmentOriginalEnd[planId] = end;
      segmentOriginalEnd[newPlanId] = end;
    } else {
      segmentOriginalEnd[newPlanId] = segmentOriginalEnd[planId];
    }
    if (votingVaults[planId] != address(0)) {
      VotingVault(votingVaults[planId]).withdrawTokens(address(this), segmentAmount);
      _setupVoting(newPlanId);
    }
    emit PlanSegmented(
      planId,
      newPlanId,
      planAmount,
      planRate,
      segmentAmount,
      segmentRate,
      plan.start,
      plan.cliff,
      plan.period,
      planEnd,
      segmentEnd
    );
  }

  /// @notice this funtion allows the holder of two plans that have the same parameters to combine them into a single surviving plan
  /// @dev all of the details of the plans must be the same except the amounts and rates may be different
  /// this function will check that the owners are the same, the ERC20 tokens are the same, the start, cliff and periods are the same.
  /// then it performs some checks on the end dates to ensure that either the end dates are the same, or if the user is combining previously segmented plans,
  /// that the original end dates of those segments are the same.
  /// if everything checks out, and the new end date of the combined plan will result in an end date equal to or later than the two plans, then they can be combined
  /// combining plans will delete the plan1 and burn the NFT related to it
  /// and then update the storage of the plan0 with the combined amount and combined rate
  /// if One of the plans has a voting vault, then that plan will be the survivor and then tokens will be transferred and consolidated into that plan
  /// if both have a voting vault, then plan0 will be the survivor and tokens consolidated to plan0 voting vault
  /// if neither have a voting vault then nothing is done for voting vaults.
  /// @param planId0 is the planId of the first plan in the combination
  /// @param planId1 is the planId of a second plan to be combined
  function _combinePlans(uint256 planId0, uint256 planId1) internal returns (uint256 survivingPlan) {
    require(ownerOf(planId0) == msg.sender, '!owner');
    require(ownerOf(planId1) == msg.sender, '!owner');
    Plan memory plan0 = plans[planId0];
    Plan memory plan1 = plans[planId1];
    require(plan0.token == plan1.token, 'token error');
    require(plan0.start == plan1.start, 'start error');
    require(plan0.cliff == plan1.cliff, 'cliff error');
    require(plan0.period == plan1.period, 'period error');
    uint256 plan0End = TimelockLibrary.endDate(plan0.start, plan0.amount, plan0.rate, plan0.period);
    uint256 plan1End = TimelockLibrary.endDate(plan1.start, plan1.amount, plan1.rate, plan1.period);
    require(
      plan0End == plan1End ||
        (segmentOriginalEnd[planId0] == segmentOriginalEnd[planId1] && segmentOriginalEnd[planId0] != 0),
      'end error'
    );
    address vault0 = votingVaults[planId0];
    address vault1 = votingVaults[planId1];
    survivingPlan = planId0;
    if (vault0 != address(0)) {
      plans[planId0].amount += plans[planId1].amount;
      (uint256 survivorRate, uint256 survivorEnd) = TimelockLibrary.calculateCombinedRate(
        plan0.amount + plan1.amount,
        plan0.rate + plan1.rate,
        plan0.start,
        plan0.period,
        plan0End
      );
      plans[planId0].rate = survivorRate;
      if (survivorEnd < plan0End) {
        require(
          survivorEnd == segmentOriginalEnd[planId0] || survivorEnd == segmentOriginalEnd[planId1],
          'original end error'
        );
      }
      if (vault1 != address(0)) {
        VotingVault(vault1).withdrawTokens(vault0, plan1.amount);
      } else {
        TransferHelper.withdrawTokens(plan0.token, vault0, plan1.amount);
      }
      delete plans[planId1];
      _burn(planId1);
      emit PlansCombined(
        planId0,
        planId1,
        survivingPlan,
        plans[planId0].amount,
        plans[planId0].rate,
        plan0.start,
        plan0.cliff,
        plan0.period,
        survivorEnd
      );
    } else if (vault1 != address(0)) {
      plans[planId1].amount += plans[planId0].amount;
      (uint256 survivorRate, uint256 survivorEnd) = TimelockLibrary.calculateCombinedRate(
        plan0.amount + plan1.amount,
        plan0.rate + plan1.rate,
        plan1.start,
        plan1.period,
        plan1End
      );
      plans[planId1].rate = survivorRate;
      if (survivorEnd < plan1End) {
        require(
          survivorEnd == segmentOriginalEnd[planId0] || survivorEnd == segmentOriginalEnd[planId1],
          'original end error'
        );
      }
      TransferHelper.withdrawTokens(plan0.token, vault1, plan0.amount);
      survivingPlan = planId1;
      delete plans[planId0];
      _burn(planId0);
      emit PlansCombined(
        planId0,
        planId1,
        survivingPlan,
        plans[planId1].amount,
        plans[planId1].rate,
        plan1.start,
        plan1.cliff,
        plan1.period,
        survivorEnd
      );
    } else {
      plans[planId0].amount += plans[planId1].amount;
      (uint256 survivorRate, uint256 survivorEnd) = TimelockLibrary.calculateCombinedRate(
        plan0.amount + plan1.amount,
        plan0.rate + plan1.rate,
        plan0.start,
        plan0.period,
        plan0End
      );
      plans[planId0].rate = survivorRate;
      if (survivorEnd < plan0End) {
        require(
          survivorEnd == segmentOriginalEnd[planId0] || survivorEnd == segmentOriginalEnd[planId1],
          'original end error'
        );
      }
      delete plans[planId1];
      _burn(planId1);
      emit PlansCombined(
        planId0,
        planId1,
        survivingPlan,
        plans[planId0].amount,
        plans[planId0].rate,
        plan0.start,
        plan0.cliff,
        plan0.period,
        survivorEnd
      );
    }
  }

  /****INTERNAL VOTING & DELEGATION FUNCTIONS*********************************************************************************************************************************************/

  /// @notice the internal function to setup a voting vault.
  /// @dev this will check that no voting vault exists already and then deploy a new voting vault contract
  // during the constructor setup of the voting vault, it will auto delegate the voting vault address to whatever the existing delegate of the  plan holder has delegated to
  // if it has not delegated yet, it will self-delegate the tokens
  /// then transfer the tokens remaining in the lockup plan to the voting vault physically
  /// @param planId is the id of the lockup plan and NFT
  function _setupVoting(uint256 planId) internal returns (address) {
    require(_isApprovedDelegatorOrOwner(msg.sender, planId), '!delegator');
    require(votingVaults[planId] == address(0), 'exists');
    Plan memory plan = plans[planId];
    VotingVault vault = new VotingVault(plan.token, ownerOf(planId));
    votingVaults[planId] = address(vault);
    TransferHelper.withdrawTokens(plan.token, address(vault), plan.amount);
    emit VotingVaultCreated(planId, address(vault));
    return address(vault);
  }

  /// @notice this internal function will physically delegate tokens held in a voting vault to a delegatee
  /// @dev if a voting vautl has not been setup yet, then the function will call the internal _setupVoting function and setup a new voting vault
  /// and then it will delegate the tokens held in the vault to the delegatee
  /// @param planId is the id of the lockup plan and NFT
  /// @param delegatee is the address of the delegatee where the tokens in the voting vault will be delegated to
  function _delegate(uint256 planId, address delegatee) internal {
    require(_isApprovedDelegatorOrOwner(msg.sender, planId), '!delegator');
    address vault = votingVaults[planId];
    if (votingVaults[planId] == address(0)) {
      vault = _setupVoting(planId);
    }
    VotingVault(vault).delegateTokens(delegatee);
  }

  /****VIEW VOTING FUNCTIONS*********************************************************************************************************************************************/

  /// @notice this function will pull all of the unclaimed tokens for a specific holder across all of their plans, based on a single ERC20 token
  /// very useful for snapshot voting, and other view functionalities. This aggregates all balances, including any in voting vaults.
  /// @param holder is the address of the beneficiary who owns the lockup plan(s)
  /// @param token is the ERC20 address of the token that is stored across the lockup plans
  function lockedBalances(address holder, address token) external view returns (uint256 lockedBalance) {
    uint256 holdersBalance = balanceOf(holder);
    for (uint256 i; i < holdersBalance; i++) {
      uint256 planId = tokenOfOwnerByIndex(holder, i);
      Plan memory plan = plans[planId];
      if (token == plan.token) {
        lockedBalance += plan.amount;
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '../libraries/TransferHelper.sol';
import '../interfaces/IVestingPlans.sol';
import '../interfaces/ILockupPlans.sol';

/// @title BatchPlanner - contract to create batches of lockup and vesting plans in bulk

contract BatchPlanner {

  /// @dev struct object that defines the parameters of a general lockup and vesting plan, that are shared by both lockup and vesting plans
  /// @param recipient is the address of the wallet receiving the plan
  /// @param amount is the amount of tokens to be locked in the plan
  /// @param start is the unix timestamp of when unlocking or vesting starts
  /// @param cliff is an optional cliff date when the plan has a second discrete date after the start when an initial chunk unlocks / vests
  /// @param rate is the amount of tokens that unlock or vest per period
  struct Plan {
    address recipient;
    uint256 amount;
    uint256 start;
    uint256 cliff;
    uint256 rate;
  }
  /// @dev event used for internal analytics and reporting only
  event BatchCreated(address indexed creator, address token, uint256 recipients, uint256 totalAmount, uint8 mintType);


  /// @notice function to create a batch of lockup plans
  /// @dev the function will pull in the entire balancde of totalAmount into the contract, then increase the approval allowance and then via loop mint lockup plans
  /// @param locker is the address of the lockup plan that the tokens will be locked in, and NFT plan provided to
  /// @param token is the address of the token that is given and locked to the individuals
  /// @param totalAmount is the total amount of tokens being locked, this has to equal the sum of all the individual amounts in the plans struct
  /// @param plans is the array of plans that contain each plan parameters
  /// @param period is the length of the period in seconds that tokens become unlocked / vested
  /// @param mintType is an internal tool to help with identifying front end applications
  function batchLockingPlans(
    address locker,
    address token,
    uint256 totalAmount,
    Plan[] calldata plans,
    uint256 period,
    uint8 mintType
  ) external {
    require(totalAmount > 0, '0_totalAmount');
    require(locker != address(0), '0_locker');
    require(token != address(0), '0_token');
    require(plans.length > 0, 'no plans');
    TransferHelper.transferTokens(token, msg.sender, address(this), totalAmount);
    SafeERC20.safeIncreaseAllowance(IERC20(token), locker, totalAmount);
    uint256 amountCheck;
    for (uint16 i; i < plans.length; i++) {
      ILockupPlans(locker).createPlan(
        plans[i].recipient,
        token,
        plans[i].amount,
        plans[i].start,
        plans[i].cliff,
        plans[i].rate,
        period
      );
      amountCheck += plans[i].amount;
    }
    require(amountCheck == totalAmount, 'totalAmount error');
    emit BatchCreated(msg.sender, token, plans.length, totalAmount, mintType);
  }


  /// @notice function to create a batch of vesting plans.
  /// @dev the function will pull in the entire balance of totalAmount to the contract, increase the allowance and then via loop mint vesting plans
  /// @param locker is the address of the lockup plan that the tokens will be locked in, and NFT plan provided to
  /// @param token is the address of the token that is given and locked to the individuals
  /// @param totalAmount is the total amount of tokens being locked, this has to equal the sum of all the individual amounts in the plans struct
  /// @param plans is the array of plans that contain each plan parameters
  /// @param period is the length of the period in seconds that tokens become unlocked / vested
  /// @param vestingAdmin is the address of the vesting admin, that will be the same for all plans created
  /// @param adminTransferOBO is an emergency toggle that allows the vesting admin to tranfer a vesting plan on behalf of a beneficiary
  /// @param mintType is an internal tool to help with identifying front end applications
  function batchVestingPlans(
    address locker,
    address token,
    uint256 totalAmount,
    Plan[] calldata plans,
    uint256 period,
    address vestingAdmin,
    bool adminTransferOBO,
    uint8 mintType
  ) external {
    require(totalAmount > 0, '0_totalAmount');
    require(locker != address(0), '0_locker');
    require(token != address(0), '0_token');
    require(plans.length > 0, 'no plans');
    TransferHelper.transferTokens(token, msg.sender, address(this), totalAmount);
    SafeERC20.safeIncreaseAllowance(IERC20(token), locker, totalAmount);
    uint256 amountCheck;
    for (uint16 i; i < plans.length; i++) {
      IVestingPlans(locker).createPlan(
        plans[i].recipient,
        token,
        plans[i].amount,
        plans[i].start,
        plans[i].cliff,
        plans[i].rate,
        period,
        vestingAdmin,
        adminTransferOBO
      );
      amountCheck += plans[i].amount;
    }
    require(amountCheck == totalAmount, 'totalAmount error');
    emit BatchCreated(msg.sender, token, plans.length, totalAmount, mintType);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '../libraries/TransferHelper.sol';
import '../libraries/TimelockLibrary.sol';
import '../interfaces/IVestingPlans.sol';
import '../interfaces/ILockupPlans.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/// @title ClaimCampaigns - The smart contract to distribute your tokens to the community via claims
/// @notice This tool allows token projects to safely, securely and efficiently distribute your tokens in large scale to your community, whereby they can claim them based on your criteria of wallet address and amount.

contract ClaimCampaigns is ReentrancyGuard {
  /// @notice the address that collects any donations given to the team
  address private donationCollector;

  /// @dev an enum defining the different types of claims to be made
  /// @param Unlocked means that tokens claimed are liquid and not locked at all
  /// @param Locked means that the tokens claimed will be locked inside a TokenLockups plan
  /// @param Vesting means the tokens claimed will be locked insite a TokenVesting plan
  enum TokenLockup {
    Unlocked,
    Locked,
    Vesting
  }

  /// @notice the struct that defines the Locked and Vesting parameters for each vesting
  /// @dev this can be ignored for Unlocked claim campaigns
  /// @param tokenLocker is the address of the TokenLockup or TokenVesting plans contract that will lock the tokens
  /// @param rate is the rate which the tokens will unlock / vest at per period. So 10 would indicate 10 tokens unlocking per period.
  /// @param start is the start date when the unlock / vesting begins
  /// @param cliff is the single cliff date for unlocking and vesting plans, when all tokens prior to the cliff remained locked and unvested
  /// @param period is the amount of seconds in each discrete period. A streaming style would have this set to 1, but a period of 1 day would be 86400, tokens only unlock at each discrete period interval
  /// @param periods is the total number of periods in the lockup, ie term_in_seconds / period.
  struct ClaimLockup {
    address tokenLocker;
    uint256 start;
    uint256 cliff;
    uint256 period;
    uint256 periods;
  }

  /// @notice Campaign is the struct that defines a claim campaign in general. The Campaign is related to a one time use, related to a merkle tree that pre defines all of the wallets and amounts those wallets can claim
  /// once the amount is 0, the campaign is ended. The campaign can also be terminated at any time.
  /// @param manager is the address of the campaign manager who is in charge of cancelling the campaign - AND if the campaign is setup for vesting, this address will be used as the vestingAdmin wallet for all of the vesting plans created
  /// the manager is typically the msg.sender wallet, but can be defined as something else in case.
  /// @param token is the address of the token to be claimed by the wallets, which is pulled into the contract during the campaign
  /// @param amount is the total amount of tokens left in the Campaign. this starts out as the entire amount in the campaign, and gets reduced each time a claim is made
  /// @param end is a unix time that can be used as a safety mechanism to put a hard end date for a campaign, this can also be far far in the future to effectively be forever claims
  /// @param tokenLockup is the enum (uint8) that describes how and if the tokens will be locked or vesting when they are claimed. If set to unlocked, claimants will just get the tokens, but if they are Locked / vesting, they will receive the NFT Tokenlockup plan or vesting plan
  /// @param root is the root of the merkle tree used for the claims.
  struct Campaign {
    address manager;
    address token;
    uint256 amount;
    uint256 end;
    TokenLockup tokenLockup;
    bytes32 root;
  }

  /// @notice this is an optional Donation that users can gift to Hedgey and team for their services. The campaign creator can define a lockup schedule of the donation of tokens, or gift them unlocked.
  /// @dev if donating tokens unlocked, set the start date to 0.
  /// @param tokenLocker is the address of the token lockup plans contract if the tokens are going to be locked
  /// @param amount is the amount of the donation
  /// @param rate is the rate the tokens unlock
  /// @param start is the start date the tokens unlock
  /// @param cliff is the cliff date the first time tokens unlock
  /// @param period is the time between each unlock
  struct Donation {
    address tokenLocker;
    uint256 amount;
    uint256 rate;
    uint256 start;
    uint256 cliff;
    uint256 period;
  }

  /// @dev we use UUIDs or CIDs to map to a specific unique campaign. The UUID or CID is typically generated when the merkle tree is created, and then that id or cid is the identifier of the file in S3 or IPFS
  mapping(bytes16 => Campaign) public campaigns;
  /// @dev the same UUID is maped to the ClaimLockup details for the specific campaign
  mapping(bytes16 => ClaimLockup) public claimLockups;
  /// @dev this maps the UUID that have already been used, so that a campaign cannot be duplicated
  mapping(bytes16 => bool) public usedIds;

  //maps campaign id to a wallet address, which is flipped to true when claimed
  mapping(bytes16 => mapping(address => bool)) public claimed;

  // events
  event CampaignStarted(bytes16 indexed id, Campaign campaign);
  event ClaimLockupCreated(bytes16 indexed id, ClaimLockup claimLockup);
  event CampaignCancelled(bytes16 indexed id);
  event TokensClaimed(bytes16 indexed id, address indexed claimer, uint256 amountClaimed, uint256 amountRemaining);
  event TokensDonated(
    bytes16 indexed id,
    address donationCollector,
    address token,
    uint256 amount,
    address tokenLocker
  );

  constructor(address _donationCollector) {
    donationCollector = _donationCollector;
  }

  /// @notice function to change the address the donations are sent to
  /// @param newCollector the address that is going to be the new recipient of donations
  function changeDonationcollector(address newCollector) external {
    require(msg.sender == donationCollector);
    donationCollector = newCollector;
  }

  /// @notice primary function for creating an unlocked claims campaign. This function will pull the amount of tokens in the campaign struct, and map the campaign to the id.
  /// @dev the merkle tree needs to be pre-generated, so that you can upload the root and the uuid for the function
  /// @param id is the uuid or CID of the file that stores the merkle tree
  /// @param campaign is the struct of the campaign info, including the total amount tokens to be distributed via claims, and the root of the merkle tree
  /// @param donation is the doantion struct that can be 0 or any amount of tokens the team wishes to donate
  function createUnlockedCampaign(
    bytes16 id,
    Campaign memory campaign,
    Donation memory donation
  ) external nonReentrant {
    require(!usedIds[id], 'in use');
    usedIds[id] = true;
    require(campaign.token != address(0), '0_address');
    require(campaign.manager != address(0), '0_manager');
    require(campaign.amount > 0, '0_amount');
    require(campaign.end > block.timestamp, 'end error');
    require(campaign.tokenLockup == TokenLockup.Unlocked, 'locked');
    TransferHelper.transferTokens(campaign.token, msg.sender, address(this), campaign.amount + donation.amount);
    if (donation.amount > 0) {
      if (donation.start > 0) {
        SafeERC20.safeIncreaseAllowance(IERC20(campaign.token), donation.tokenLocker, donation.amount);
        ILockupPlans(donation.tokenLocker).createPlan(
          donationCollector,
          campaign.token,
          donation.amount,
          donation.start,
          donation.cliff,
          donation.rate,
          donation.period
        );
      } else {
        TransferHelper.withdrawTokens(campaign.token, donationCollector, donation.amount);
      }
      emit TokensDonated(id, donationCollector, campaign.token, donation.amount, donation.tokenLocker);
    }
    campaigns[id] = campaign;
    emit CampaignStarted(id, campaign);
  }

  /// @notice primary function for creating an locked or vesting claims campaign. This function will pull the amount of tokens in the campaign struct, and map the campaign and claimLockup to the id.
  /// additionally it will check that the lockup details are valid, and perform an allowance increase to the contract for when tokens are claimed they can be pulled.
  /// @dev the merkle tree needs to be pre-generated, so that you can upload the root and the uuid for the function
  /// @param id is the uuid or CID of the file that stores the merkle tree
  /// @param campaign is the struct of the campaign info, including the total amount tokens to be distributed via claims, and the root of the merkle tree, plus the lockup type of either 1 (lockup) or 2 (vesting)
  /// @param claimLockup is the struct that defines the characteristics of the lockup for each token claimed.
  /// @param donation is the doantion struct that can be 0 or any amount of tokens the team wishes to donate
  function createLockedCampaign(
    bytes16 id,
    Campaign memory campaign,
    ClaimLockup memory claimLockup,
    Donation memory donation
  ) external nonReentrant {
    require(!usedIds[id], 'in use');
    usedIds[id] = true;
    require(campaign.token != address(0), '0_address');
    require(campaign.manager != address(0), '0_manager');
    require(campaign.amount > 0, '0_amount');
    require(campaign.end > block.timestamp, 'end error');
    require(campaign.tokenLockup != TokenLockup.Unlocked, '!locked');
    require(claimLockup.tokenLocker != address(0), 'invalide locker');
    TransferHelper.transferTokens(campaign.token, msg.sender, address(this), campaign.amount + donation.amount);
    if (donation.amount > 0) {
      if (donation.start > 0) {
        SafeERC20.safeIncreaseAllowance(IERC20(campaign.token), donation.tokenLocker, donation.amount);
        ILockupPlans(donation.tokenLocker).createPlan(
          donationCollector,
          campaign.token,
          donation.amount,
          donation.start,
          donation.cliff,
          donation.rate,
          donation.period
        );
      } else {
        TransferHelper.withdrawTokens(campaign.token, donationCollector, donation.amount);
      }
      emit TokensDonated(id, donationCollector, campaign.token, donation.amount, donation.tokenLocker);
    }
    claimLockups[id] = claimLockup;
    SafeERC20.safeIncreaseAllowance(IERC20(campaign.token), claimLockup.tokenLocker, campaign.amount);
    campaigns[id] = campaign;
    emit ClaimLockupCreated(id, claimLockup);
    emit CampaignStarted(id, campaign);
  }

  /// @notice this is the primary function for the claimants to claim their tokens
  /// @dev the claimer will need to know the uuid of the campiagn, plus have access to the amount of tokens they are claiming and the merkle tree proof
  /// @dev if the claimer doesnt have this information the function will fail as it will not pass the verify validation
  /// the leaf of each merkle tree is the hash of the wallet address plus the amount of tokens claimable
  /// @dev once a user has claimed tokens, they cannot perform a second claim
  /// @dev the amount of tokens in the campaign is reduced by the amount of the claim
  /// @param campaignId is the id of the campaign stored in storage
  /// @param proof is the merkle tree proof that maps to their unique leaf in the merkle tree
  /// @param claimAmount is the amount of tokens they are eligible to claim
  /// this function will verify and validate the eligibilty of the claim, and then process the claim, by delivering unlocked or locked / vesting tokens depending on the setup of the claim campaign.
  function claimTokens(bytes16 campaignId, bytes32[] memory proof, uint256 claimAmount) external nonReentrant {
    require(!claimed[campaignId][msg.sender], 'already claimed');
    Campaign memory campaign = campaigns[campaignId];
    require(campaign.end > block.timestamp, 'campaign ended');
    require(verify(campaign.root, proof, msg.sender, claimAmount), '!eligible');
    require(campaign.amount >= claimAmount, 'campaign unfunded');
    claimed[campaignId][msg.sender] = true;
    campaigns[campaignId].amount -= claimAmount;
    if (campaigns[campaignId].amount == 0) {
      delete campaigns[campaignId];
    }
    if (campaign.tokenLockup == TokenLockup.Unlocked) {
      TransferHelper.withdrawTokens(campaign.token, msg.sender, claimAmount);
    } else {
      ClaimLockup memory c = claimLockups[campaignId];
      uint256 rate;
      if (claimAmount % c.periods == 0) {
        rate = claimAmount / c.periods;
      } else {
        if (claimAmount % (c.periods - 1) == 0) {
          rate = claimAmount / c.periods + 1;
        } else {
          rate = claimAmount / (c.periods - 1);
        }
      }
      uint256 start = c.start == 0 ? block.timestamp : c.start;
      if (campaign.tokenLockup == TokenLockup.Locked) {
        ILockupPlans(c.tokenLocker).createPlan(msg.sender, campaign.token, claimAmount, start, c.cliff, rate, c.period);
      } else {
        IVestingPlans(c.tokenLocker).createPlan(
          msg.sender,
          campaign.token,
          claimAmount,
          start,
          c.cliff,
          rate,
          c.period,
          campaign.manager,
          false
        );
      }
    }
    emit TokensClaimed(campaignId, msg.sender, claimAmount, campaigns[campaignId].amount);
  }

  /// @notice this function allows the campaign manager to cancel an ongoing campaign at anytime. Cancelling a campaign will return any unclaimed tokens, and then prevent anyone from claiming additional tokens
  /// @param campaignId is the id of the campaign to be cancelled
  function cancelCampaign(bytes16 campaignId) external nonReentrant {
    Campaign memory campaign = campaigns[campaignId];
    require(campaign.manager == msg.sender, '!manager');
    delete campaigns[campaignId];
    delete claimLockups[campaignId];
    TransferHelper.withdrawTokens(campaign.token, msg.sender, campaign.amount);
    emit CampaignCancelled(campaignId);
  }

  /// @dev the internal verify function from the open zepellin library.
  /// this function inputs the root, proof, wallet address of the claimer, and amount of tokens, and then computes the validity of the leaf with the proof and root.
  /// @param root is the root of the merkle tree
  /// @param proof is the proof for the specific leaf
  /// @param claimer is the address of the claimer used in making the leaf
  /// @param amount is the amount of tokens to be claimed, the other piece of data in the leaf
  function verify(bytes32 root, bytes32[] memory proof, address claimer, uint256 amount) public pure returns (bool) {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(claimer, amount))));
    require(MerkleProof.verify(proof, root, leaf), 'Invalid proof');
    return true;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '../libraries/TimelockLibrary.sol';

/// @notice This contract is the storage contract for the Lockup Plans contracts.
/// it contains the storage of the lockup plan object (Plan struct), as well as the events that the lockup plan contracts emit

contract LockupStorage {
  /// @dev the Plan is the storage in a struct of the tokens that are locked and being unlocked
  /// @param token is the token address being timelocked
  /// @param amount is the current amount of tokens locked in the lockup plan, both unclaimed unlocked and still locked tokens. This parameter is updated each time tokens are redeemed, reset to the new remaining locked and unclaimed amount
  /// @param start is the start date when token unlock begins or began. This parameter gets updated each time tokens are redeemed and claimed, reset to the most recent redeem time
  /// @param cliff is an optional field to add a single cliff date prior to which the tokens cannot be redeemed, this does not change
  /// @param rate is the amount of tokens that unlock in a period. This parameter is constand for each plan. 
  /// @param period is the length of time in between each discrete time when tokens unlock. If this is set to 1, then tokens unlocke every second. Otherwise the period is longer to allow for interval lockup plans. 
  struct Plan {
    address token;
    uint256 amount;
    uint256 start;
    uint256 cliff;
    uint256 rate;
    uint256 period;
  }

  /// @dev a mapping of the planId to the Plan struct. This is also mapped of the NFT token ID to the Plan struct, as the planId is the NFT token Id. 
  mapping(uint256 => Plan) public plans;

  /// @dev this stores the original end date of a plan. This is only used when a token is segmented, which sometimes results in a new end that is longer than the original, 
  /// the original end date is stored for the case of recombining those plans. 
  mapping(uint256 => uint256) public segmentOriginalEnd;

  ///@notice event emitted when a new lockup plan is created, emits the NFT and planId, as well as all of the info from the plan struct
  event PlanCreated(
    uint256 indexed id,
    address indexed recipient,
    address indexed token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 end,
    uint256 rate,
    uint256 period
  );

  /// @notice event emitted when a beneficiary redeems some or all of the tokens in their plan. 
  /// It emits the id of the plan, as well as the amount redeemed, any remaining unvested or unclaimed tokens and the date that was the effective new start date, the reset date
  event PlanRedeemed(uint256 indexed id, uint256 amountRedeemed, uint256 planRemainder, uint256 resetDate);

  /// @notice this event is emitted when a plan owner segments a plan into a new plan. The event spits out all of the details that have changed for the original plan and the new segmented plan
  event PlanSegmented(
    uint256 indexed id,
    uint256 indexed segmentId,
    uint256 newPlanAmount,
    uint256 newPlanRate,
    uint256 segmentAmount,
    uint256 segmentRate,
    uint256 start,
    uint256 cliff,
    uint256 period,
    uint256 newPlanEnd,
    uint256 segmentEnd
  );

  /// @notice this event is emitted when two plans with the same parameters are combined, it emits the two combined plans ids, the surviving plan id, and the details of the surviving plan
  event PlansCombined(
    uint256 indexed id0,
    uint256 indexed id1,
    uint256 indexed survivingId,
    uint256 amount,
    uint256 rate,
    uint256 start,
    uint256 cliff,
    uint256 period,
    uint256 end
  );

  /// @notice public function to get the balance of a plan, this function is used by the contracts to calculate how much can be redeemed, and how to reset the start date
  /// @param planId is the NFT token ID and plan Id
  /// @param timeStamp is the effective current time stamp, can be polled for the future for estimating redeemable tokens
  /// @param redemptionTime is the time of the request that the user is attemptint to redeem tokens, which can be prior to the timeStamp, though not beyond it.
  function planBalanceOf(
    uint256 planId,
    uint256 timeStamp,
    uint256 redemptionTime
  ) public view returns (uint256 balance, uint256 remainder, uint256 latestUnlock) {
    Plan memory plan = plans[planId];
    (balance, remainder, latestUnlock) = TimelockLibrary.balanceAtTime(
      plan.start,
      plan.cliff,
      plan.amount,
      plan.rate,
      plan.period,
      timeStamp,
      redemptionTime
    );
  }

  /// @dev function to calculate the end date in seconds of a given vesting plan
  /// @param planId is the NFT token ID
  function planEnd(uint256 planId) external view returns (uint256 end) {
    Plan memory plan = plans[planId];
    end = TimelockLibrary.endDate(plan.start, plan.amount, plan.rate, plan.period);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

abstract contract PlanDelegator is ERC721Enumerable {
  // mapping of tokenId to address who can delegate an NFT on behalf of the owner
  /// @dev follows tokenApprovals logic
  mapping(uint256 => address) private _approvedDelegators;

  /// @dev operatorApprovals simialr to ERC721 standards
  mapping(address => mapping(address => bool)) private _approvedOperatorDelegators;

  /// @dev event that is emitted when a single plan delegator has been approved
  event DelegatorApproved(uint256 indexed id, address owner, address delegator);

  /// @dev event emit when the operator delegator has been approved to manage all delegation of a single address
  event ApprovalForAllDelegation(address owner, address operator, bool approved);

  /// @notice function to assign a single planId to a delegator. The delegator then has authority to call functions on other contracts such as delegate
  /// @param delegator is the address of the delegator who can delegate on behalf of the nft owner
  /// @param planId is the id of the vesting or lockup plan
  function approveDelegator(address delegator, uint256 planId) public virtual {
    address owner = ownerOf(planId);
    require(msg.sender == owner || isApprovedForAllDelegation(owner, msg.sender), '!ownerOperator');
    require(delegator != msg.sender, '!self approval');
    _approveDelegator(delegator, planId);
  }

  /// @notice function that performs both the approveDelegator function and approves a spender
  /// @param spender is the address who is approved to spend and is also a Delegator
  /// @param planId is the vesting plan id
  function approveSpenderDelegator(address spender, uint256 planId) public virtual {
    address owner = ownerOf(planId);
    require(
      msg.sender == owner || (isApprovedForAllDelegation(owner, msg.sender) && isApprovedForAll(owner, msg.sender)),
      '!ownerOperator'
    );
    require(spender != msg.sender, '!self approval');
    _approveDelegator(spender, planId);
    _approve(spender, planId);
  }

  /// @notice this function sets an address to be an operator delegator for the msg.sender, whereby the operator can delegate all tokens owned by the msg.sender
  /// the operator can also approve other single plan delegators
  /// @param operator address of the operator for the msg.sender
  /// @param approved boolean for approved if true, and false if not
  function setApprovalForAllDelegation(address operator, bool approved) public virtual {
    _setApprovalForAllDelegation(msg.sender, operator, approved);
  }

  /// @notice functeion to set the approval operator for both delegation and for spending NFTs of the msg.sender
  /// @param operator is the address who will be allowed to spend and delegate
  /// @param approved is the bool determining if they are allowed or not
  function setApprovalForOperator(address operator, bool approved) public virtual {
    _setApprovalForAllDelegation(msg.sender, operator, approved);
    _setApprovalForAll(msg.sender, operator, approved);
  }

  /// @notice internal function to update the storage of approvedDelegators and emit the event
  function _approveDelegator(address delegator, uint256 planId) internal virtual {
    _approvedDelegators[planId] = delegator;
    emit DelegatorApproved(planId, ownerOf(planId), delegator);
  }

  /// @notice internal function to update the storage of approvedOperatorDelegators, and emit the event
  function _setApprovalForAllDelegation(address owner, address operator, bool approved) internal virtual {
    require(owner != operator, '!operator');
    _approvedOperatorDelegators[owner][operator] = approved;
    emit ApprovalForAllDelegation(owner, operator, approved);
  }

  /// @notice we call the beforeTokenTransfer hook to delete the approvedDelegators storage variable so that the Delegator approval does not travel with the NFT when transferred
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    delete _approvedDelegators[firstTokenId];
  }

  /// @notice function to get the approved delegator of a single planId
  function getApprovedDelegator(uint256 planId) public view returns (address) {
    _requireMinted(planId);
    return _approvedDelegators[planId];
  }

  /// @notice function to evaluate if an operator is approved to manage delegations of an owner address
  function isApprovedForAllDelegation(address owner, address operator) public view returns (bool) {
    return _approvedOperatorDelegators[owner][operator];
  }

  /// @notice internal view function to determine if a delegator, typically the msg.sender is allowed to delegate a token, based on being either the Owner, Delegator or Operator.
  function _isApprovedDelegatorOrOwner(address delegator, uint256 planId) internal view returns (bool) {
    address owner = ownerOf(planId);
    return (delegator == owner ||
      isApprovedForAllDelegation(owner, delegator) ||
      getApprovedDelegator(planId) == delegator);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

contract URIAdmin {
    /// @dev baseURI is the URI directory where the metadata is stored
  string public baseURI;
  /// @dev bool to ensure uri has been set before admin can be deleted
  bool internal uriSet;
  /// @dev admin for setting the baseURI;
  address internal uriAdmin;

  /// @notice event for when a new URI is set for the NFT metadata linking
  event URISet(string newURI);

  /// @notice event for when the URI admin is deleted
  event URIAdminDeleted(address _admin);


  /// @notice function to set the base URI after the contract has been launched, only the admin can call
  /// @param _uri is the new baseURI for the metadata
  function updateBaseURI(string memory _uri) external {
    require(msg.sender == uriAdmin, '!ADMIN');
    baseURI = _uri;
    uriSet = true;
    emit URISet(_uri);
  }

  /// @notice function to delete the admin once the uri has been set
  function deleteAdmin() external {
    require(msg.sender == uriAdmin, '!ADMIN');
    require(uriSet, '!SET');
    delete uriAdmin;
    emit URIAdminDeleted(msg.sender);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '../libraries/TimelockLibrary.sol';

/// @notice This is the storage contract for the Vesting Plans
/// it contains the logic of the vesting plan object (struct), as well as the events that are utilized and emitted by the contracts

contract VestingStorage {
  /// @dev the Plan is the storage in a struct of the tokens that are currently being vested
  /// @param token is the token address being timelocked
  /// @param amount is the current amount of tokens locked in the vesting plan, both unclaimed vested and unvested tokens. This parameter is updated each time tokens are redeemed, reset to the new remaining unvested and unclaimed amount
  /// @param start is the start date when token vesting begins or began. This parameter gets updated each time tokens are redeemed and claimed, reset to the most recent redeem time
  /// @param cliff is an optional field to add a single cliff date prior to which the tokens cannot be redeemed, this does not change
  /// @param rate is the amount of tokens that vest in a period. This parameter is constand for each plan. 
  /// @param period is the length of time in between each discrete time when tokens vest. If this is set to 1, then tokens unlocke every second. Otherwise the period is longer to allow for interval vesting plans. 
  /// @param vestingAdmin is the adress of the administrator of the plans who can revoke plans at any time prior to them fully vesting. They may also be allowed to transfer plans on behalf of the beneficiary. 
  /// @param adminTransferOBO is a toggle that when true allows a vesting admin to transfer plans on behalf of (OBO) beneficiaries to another wallet. This is really just used for emergencies. 
  struct Plan {
    address token;
    uint256 amount;
    uint256 start;
    uint256 cliff;
    uint256 rate;
    uint256 period;
    address vestingAdmin;
    bool adminTransferOBO;
  }

  /// @dev a mapping of the planId to the Plan struct. This is also mapped of the NFT token ID to the Plan struct, as the planId is the NFT token Id. 
  mapping(uint256 => Plan) public plans;

  ///@notice event emitted when a new vesting plan is created, emits the NFT and planId, as well as all of the info from the plan struct
  event PlanCreated(
    uint256 indexed id,
    address indexed recipient,
    address indexed token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 end,
    uint256 rate,
    uint256 period,
    address vestingAdmin,
    bool adminTransferOBO
  );

  /// @notice event emitted when a beneficiary redeems some or all of the tokens in their plan. 
  /// It emits the id of the plan, as well as the amount redeemed, any remaining unvested or unclaimed tokens and the date that was the effective new start date, the reset date. 
  event PlanRedeemed(uint256 indexed id, uint256 amountRedeemed, uint256 planRemainder, uint256 resetDate);

  /// @notice event that is emitted when a plan is revoked. emits the plan Id as well as the amount that is vested and redeemed to the beneficiary, and the amount that is revoked and sent to the vesting admin. 
  event PlanRevoked(uint256 indexed id, uint256 amountRedeemed, uint256 revokedAmount);

  /// @notice event emitted when a vesting admin changes itself, assigning a new vesting admin to the plan
  event VestingPlanAdminChanged(uint256 indexed id, address _newVestingAdmin);

  /// @notice event emitted when a plan admin transfers an plan and NFT on behalf of a beneficiary from one wallet address to another
  event PlanTransferredByVestingAdmin(uint256 indexed id, address indexed from, address indexed to);

  event PlanVestingAdminTransferToggle(uint256 indexed id, bool transferable);

  /// @notice public function to get the balance of a plan, this function is used by the contracts to calculate how much can be redeemed and revoked, and how to reset the start date
  /// @param planId is the NFT token ID and plan Id
  /// @param timeStamp is the effective current time stamp, can be polled for the future for estimating redeemable tokens
  /// @param redemptionTime is the time of the request that the user is attemptint to redeem tokens, which can be prior to the timeStamp, though not beyond it. 
  function planBalanceOf(
    uint256 planId,
    uint256 timeStamp,
    uint256 redemptionTime
  ) public view returns (uint256 balance, uint256 remainder, uint256 latestUnlock) {
    Plan memory plan = plans[planId];
    (balance, remainder, latestUnlock) = TimelockLibrary.balanceAtTime(
      plan.start,
      plan.cliff,
      plan.amount,
      plan.rate,
      plan.period,
      timeStamp,
      redemptionTime
    );
  }

  /// @dev function to calculate the end date in seconds of a given vesting plan
  /// @param planId is the NFT token ID
  function planEnd(uint256 planId) public view returns (uint256 end) {
    Plan memory plan = plans[planId];
    end = TimelockLibrary.endDate(plan.start, plan.amount, plan.rate, plan.period);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '../libraries/TransferHelper.sol';

interface IGovernanceToken {
    function delegate(address delegatee) external;
    function delegates(address wallet) external view returns (address delegate);
}

contract VotingVault {

    address public token;
    address public controller;

    constructor(address _token, address beneficiary) {
        controller = msg.sender;
        token = _token;
        address existingDelegate = IGovernanceToken(token).delegates(beneficiary);
        if(existingDelegate != address(0)) IGovernanceToken(token).delegate(existingDelegate);
        else IGovernanceToken(token).delegate(beneficiary);
    }

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    function delegateTokens(address delegatee) external onlyController {
        uint256 balanceCheck = IERC20(token).balanceOf(address(this));
        IGovernanceToken(token).delegate(delegatee);
        // check to make sure delegate function is not malicious
        require(balanceCheck == IERC20(token).balanceOf(address(this)), 'balance error');
    }

    function withdrawTokens(address to, uint256 amount) external onlyController {
        TransferHelper.withdrawTokens(token, to, amount);
        if (IERC20(token).balanceOf(address(this)) == 0) {
            delete token;
            delete controller;
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';

contract FakeToken is ERC20Votes {
  uint8 private _decimals;

  constructor(uint256 initialSupply, string memory name, string memory symbol) ERC20Permit(name) ERC20(name, symbol) {
    _decimals = 18;
    _mint(msg.sender, initialSupply);
  }

  function mint(uint256 amount) public {
    _mint(msg.sender, amount);
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }


  //testing specifically for contracts that would try to trick the vesting plans to trnasfer tokens away
  function delegate(address delegatee) public override {
    uint256 amount = balanceOf(msg.sender);
    _transfer(msg.sender, delegatee, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract NonVotingToken is ERC20 {
  uint8 private _decimals;

  constructor(uint256 initialSupply, string memory name, string memory symbol) ERC20(name, symbol) {
    _decimals = 18;
    _mint(msg.sender, initialSupply);
  }

  function mint(uint256 amount) public {
    _mint(msg.sender, amount);
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';

contract Token is ERC20Votes {
  uint8 private _decimals;

  constructor(uint256 initialSupply, string memory name, string memory symbol) ERC20Permit(name) ERC20(name, symbol) {
    _decimals = 18;
    _mint(msg.sender, initialSupply);
  }

  function mint(uint256 amount) public {
    _mint(msg.sender, amount);
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '../ERC721Delegate/ERC721Delegate.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../libraries/TransferHelper.sol';
import '../libraries/TimelockLibrary.sol';
import '../sharedContracts/URIAdmin.sol';
import '../sharedContracts/VestingStorage.sol';

/// @title TokenVestingPlans - An efficient way to allocate tokens to employees that vest over time
/// @notice This contract allows people to grant tokens to beneficiaries that vest over time with the added functionalities;
/// Each vesting plan is a unique NFT, leveraging the backbone of the ERC721 contract to represent a unique vesting plan
/// 1. Revokable: plans can be revoked and unvested tokens returned to the company (vesting admin)
/// 2. Soul Bound: plans are by default soul bound and not transferable, however can be transferred by an admin in emergencies
/// 3. Governance optimized for snapshot voting: These are built to allow beneficiaries to vote with their unvested tokens on snapshot, or delegate them to other delegatees
/// 4. Beneficiary Claims: Beneficiaries get to choose when to claim their tokens, and can claim partial amounts that are less than the amount they vested for tax optimization

contract TokenVestingPlans is ERC721Delegate, VestingStorage, ReentrancyGuard, URIAdmin {
  /// @notice uses counters for incrementing token IDs which are the planIds
  using Counters for Counters.Counter;
  Counters.Counter private _planIds;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    uriAdmin = msg.sender;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /****CORE EXTERNAL FUNCTIONS*********************************************************************************************************************************************/

  /// @notice function to create a vesting plan.
  /// @dev this function will pull the tokens into this contract for escrow, increment the planIds, mint an NFT to the recipient, and create the storage Plan and map it to the newly minted NFT token ID in storage
  /// @param recipient the address of the recipient and beneficiary of the plan
  /// @param token the address of the ERC20 token
  /// @param amount the amount of tokens to be locked in the plan
  /// @param start the start date of the vesting plan, unix time
  /// @param cliff a cliff date which is a discrete date where tokens are not vested until this date, and then vest in a large single chunk on the cliff date
  /// @param rate the amount of tokens that vest in a single period
  /// @param period the amount of time in between each vesting time stamp, in seconds. A period of 1 means that tokens vest every second in a 'streaming' style.
  /// @param vestingAdmin is the address of an administrator in charge of revoking the plan, pulling back any unvested tokens to the vestingAdmin address
  /// @param adminTransferOBO is an optional toggle to allow the vestingAdmin to transfer a plan and NFT to another wallet on behalf of (OBO) a beneficiary. To be used only for emergencies.
  function createPlan(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 rate,
    uint256 period,
    address vestingAdmin,
    bool adminTransferOBO
  ) external nonReentrant returns (uint256 newPlanId) {
    require(recipient != address(0), '0_recipient');
    require(token != address(0), '0_token');
    (uint256 end, bool valid) = TimelockLibrary.validateEnd(start, cliff, amount, rate, period);
    require(valid);
    _planIds.increment();
    newPlanId = _planIds.current();
    TransferHelper.transferTokens(token, msg.sender, address(this), amount);
    plans[newPlanId] = Plan(token, amount, start, cliff, rate, period, vestingAdmin, adminTransferOBO);
    _safeMint(recipient, newPlanId);
    emit PlanCreated(
      newPlanId,
      recipient,
      token,
      amount,
      start,
      cliff,
      end,
      rate,
      period,
      vestingAdmin,
      adminTransferOBO
    );
  }

  /// @notice function for a beneficiary to redeem vested tokens from a group of plans
  /// @dev this will call an internal function for processing the actual redemption of tokens, which will withdraw vested tokens and deliver them to the beneficiary
  /// @dev this function will redeem all claimable and vested tokens up to the current block.timestamp
  /// @param planIds is the array of the NFT planIds that are to be redeemed. If any have no redeemable balance they will be skipped.
  function redeemPlans(uint256[] calldata planIds) external nonReentrant {
    _redeemPlans(planIds, block.timestamp);
  }

  /// @notice function for a beneficiary to redeem vested tokens from a group of plans
  /// @dev this will call an internal function for processing the actual redemption of tokens, which will withdraw vested tokens and deliver them to the beneficiary
  /// @dev this function will redeem only a partial amount of tokens based on a redemption timestamp that is in the past. This allows holders to redeem less than their fully vested amount for various reasons
  /// @param planIds is the array of the NFT planIds that are to be redeemed. If any have no redeemable balance they will be skipped.
  /// @param redemptionTime is the timestamp which will calculate the amount of tokens redeemable and redeem them based on that timestamp
  function partialRedeemPlans(uint256[] calldata planIds, uint256 redemptionTime) external nonReentrant {
    require(redemptionTime < block.timestamp, '!future');
    _redeemPlans(planIds, redemptionTime);
  }

  /// @notice this function will redeem all plans owned by a single wallet - useful for custodians or other intermeidaries that do not have the ability to lookup individual planIds
  /// @dev this will iterate through all of the plans owned by the wallet based on the ERC721Enumerable backbone, and redeem each one with a redemption time of the current block.timestamp
  function redeemAllPlans() external nonReentrant {
    uint256 balance = balanceOf(msg.sender);
    uint256[] memory planIds = new uint256[](balance);
    for (uint256 i; i < balance; i++) {
      uint256 planId = tokenOfOwnerByIndex(msg.sender, i);
      planIds[i] = planId;
    }
    _redeemPlans(planIds, block.timestamp);
  }

  /// @notice the function for a vestingAdmin to revoke vesting plans.
  /// @dev this will call an internal function to revoke plans, whereby unvested tokens will be returned to the vestingAdmin, and any tokens that are vested will be delivered to the beneficiary(s)
  /// @param planIds is the array of the plan ids to be redeemed. the caller must be the vesting admin for all of the plans.
  function revokePlans(uint256[] calldata planIds) external nonReentrant {
    for (uint256 i; i < planIds.length; i++) {
      _revokePlan(planIds[i], block.timestamp);
    }
  }

  /// @notice this function allows a vesting admin to revoke a plan with a future date
  /// @dev different than the revokePlans function this takes an input time that is used for all of the plan revoking, which must be at least the current time stamp or future
  /// @param planIds is the array of the plan ids to be redeemed. the caller must be the vesting admin for all of the plans.
  /// @param revokeTime is the future time which the plans will be revoked effectively at
  function futureRevokePlans(uint256[] calldata planIds, uint256 revokeTime) external nonReentrant {
    require(revokeTime >= block.timestamp, '!past revoke');
    for (uint256 i; i < planIds.length; i++) {
      _revokePlan(planIds[i], revokeTime);
    }
  }

  /// @notice the function for a vestingAdmin to assing a new vestingAdmin wallet for a specific plan. Used in emergencies where DAOs are changing multi-sigs or other events
  /// @dev the new vesting admin address cannot be the beneficiary of the plan
  /// @param planId is the NFT token id of the plan
  /// @param newVestingAdmin is the address which the vesting admin of the plan will be assigned
  function changeVestingPlanAdmin(uint256 planId, address newVestingAdmin) external {
    Plan storage plan = plans[planId];
    require(msg.sender == plan.vestingAdmin, '!vestingAdmin');
    require(ownerOf(planId) != newVestingAdmin, '!planOwner');
    plan.vestingAdmin = newVestingAdmin;
    emit VestingPlanAdminChanged(planId, newVestingAdmin);
  }

  /****EXTERNAL VOTING & DELEGATION FUNCTIONS*********************************************************************************************************************************************/
  /// @notice delegation functions do not move any tokens and do not alter any information about the vesting plan object.
  /// the specifically delegate the NFTs using the ERC721Delegate.sol extension.
  /// Use the dedicated snapshot strategy 'hedgey-delegate' to leverage the delegation functions for voting with snapshot

  /// @notice function to delegate an individual NFT tokenId to another wallet address.
  /// @dev by default all plans are self delegated, this allows for the owner of a plan to delegate their NFT to a different address. This calls the internal _delegateToken function from ERC721Delegate.sol contract
  /// @param planId is the token Id of the NFT and vesting plan to be delegated
  /// @param delegatee is the address that the plan will be delegated to
  function delegate(uint256 planId, address delegatee) external {
    _delegateToken(delegatee, planId);
  }

  /// @notice functeion to delegate multiple plans to multiple delegates in a single transaction
  /// @dev this also calls the internal _delegateToken function from ERC721Delegate.sol to delegate an NFT to another wallet.
  /// @dev this function iterates through the array of plans and delegatees, delegating each individual NFT.
  /// @param planIds is the array of planIds that will be delegated
  /// @param delegatees is the array of addresses that each corresponding planId will be delegated to
  function delegatePlans(uint256[] calldata planIds, address[] calldata delegatees) external nonReentrant {
    require(planIds.length == delegatees.length, 'array error');
    for (uint256 i; i < planIds.length; i++) {
      _delegateToken(delegatees[i], planIds[i]);
    }
  }

  /// @notice function to delegate all plans related to a specific token to a single delegatee address
  /// @dev this function pulls the balances of a wallet, checks that the token in the vesting plan matches the token input param, and then delegates it to the delegatee
  /// @param token is the address of the ERC20 tokens that are locked in the vesting plans desired to be delegated
  /// @param delegatee is the address of the delegate that all of the NFTs / plans will be delegated to.
  function delegateAll(address token, address delegatee) external {
    uint256 balance = balanceOf(msg.sender);
    for (uint256 i; i < balance; i++) {
      uint256 planId = tokenOfOwnerByIndex(msg.sender, i);
      if (plans[planId].token == token) _delegateToken(delegatee, planId);
    }
  }

  /****CORE INTERNAL FUNCTIONS*********************************************************************************************************************************************/

  /// @notice function that will intake an array of planIds and a redemption time, and then check the balances that are available to be redeemed
  /// @dev if the nft has an available balance, it is then passed on to the _redeemPlan function for further processing
  /// if there is no balance to be redeemed, the plan is skipped from being processed
  /// @param planIds is the array of plans to be redeemed
  /// @param redemptionTime is the requested redemption time, either the current block.timestamp or a timestamp from the past, but must be greater than the start date
  function _redeemPlans(uint256[] memory planIds, uint256 redemptionTime) internal {
    for (uint256 i; i < planIds.length; i++) {
      (uint256 balance, uint256 remainder, uint256 latestUnlock) = planBalanceOf(
        planIds[i],
        block.timestamp,
        redemptionTime
      );
      if (balance > 0) _redeemPlan(planIds[i], balance, remainder, latestUnlock);
    }
  }

  /// @notice internal function that process the redemption for a single vesting plan
  /// @dev this takes the inputs from the _redeemPlans and processes the redemption delivering the available balance of redeemable tokens to the beneficiary
  /// if the plan is fully redeemed, as defined that the balance == amount, then the plan is deleted and NFT burned
  // if the plan is not fully redeemed, then the storage of start and amount are updated to reflect the remaining amount and most recent time redeemed for the new start date
  /// @param planId is the id of the vesting plan and NFT
  /// @param balance is the available redeemable balance
  /// @param remainder is the amount of tokens that are still unvested in the plan, and will be the new amount in the plan storage
  /// @param latestUnlock is the most recent timestamp for when redemption occured. Because periods may be longer than 1 second, the latestUnlock time may be the current block time, or the timestamp of the most recent period timestamp
  function _redeemPlan(uint256 planId, uint256 balance, uint256 remainder, uint256 latestUnlock) internal {
    require(ownerOf(planId) == msg.sender, '!owner');
    address token = plans[planId].token;
    if (remainder == 0) {
      delete plans[planId];
      _burn(planId);
    } else {
      plans[planId].amount = remainder;
      plans[planId].start = latestUnlock;
    }
    TransferHelper.withdrawTokens(token, msg.sender, balance);
    emit PlanRedeemed(planId, balance, remainder, latestUnlock);
  }

  /// @notice the internal function to revoke a vesting plan
  /// @dev this is called by the external revokePlans function, which inputs the msg.sender as the vestingAdmin and the planId from the inputs
  /// this function checks that the vestingAdmin is the vestingAdmin, and that there is actually a revokable balance.
  /// The function then withdraws the unvested tokens that are revoked, delivering them to the vestingAdmin
  /// the function will not automatically transfer the tokens to the plan beneficiary.
  /// If the vesting plan has no balance left, because the remainder is the entire amount then it will be burned and deleted
  /// otherwise the NFT will still exist, but the amount is set to the balance that is still to be vested so it can vest along the same time as its original vesting terms
  /// but the vestingAdmin is set to 0 address so that it cannot be revoked again or transferred
  /// if the plan has an external voting vault setup, then tokens will be withdrawn from the voting vault rather than this contract address
  /// finally the function deletes the plan held in storage and burns the NFT.
  /// @param planId is the id of the plan and NFT
  /// @param revokeTime is the time that the plan will be revoked effectively at, which can be in the future but not the past
  function _revokePlan(uint256 planId, uint256 revokeTime) internal {
    Plan memory plan = plans[planId];
    require(msg.sender == plan.vestingAdmin, '!vestingAdmin');
    (uint256 balance, uint256 remainder, ) = planBalanceOf(planId, block.timestamp, revokeTime);
    require(remainder > 0, '!Remainder');
    if (balance == 0) {
      delete plans[planId];
      _burn(planId);
    } else {
      plans[planId].amount = balance;
      plans[planId].vestingAdmin = address(0);
    }
    TransferHelper.withdrawTokens(plan.token, msg.sender, remainder);
    emit PlanRevoked(planId, balance, remainder);
  }

  /****VIEW VOTING FUNCTIONS*********************************************************************************************************************************************/

  /// @notice this function will pull all of the unclaimed tokens for a specific holder across all of their plans, based on a single ERC20 token
  /// very useful for snapshot voting, and other view functionalities
  /// @param holder is the address of the beneficiary who owns the vesting plan(s)
  /// @param token is the ERC20 address of the token that is stored across the vesting plans
  function lockedBalances(address holder, address token) external view returns (uint256 lockedBalance) {
    uint256 holdersBalance = balanceOf(holder);
    for (uint256 i; i < holdersBalance; i++) {
      uint256 planId = tokenOfOwnerByIndex(holder, i);
      Plan memory plan = plans[planId];
      if (token == plan.token) {
        lockedBalance += plan.amount;
      }
    }
  }

  /// @notice this function will pull all of the tokens locked in vesting plans where the NFT has been delegated to a specific delegatee wallet address
  /// this is useful for the snapshot strategy hedgey-delegate, polling this function based on the wallet signed into snapshot
  /// by default all NFTs are self-delegated when they are minted.
  /// @param delegatee is the address of the delegate where NFTs have been delegated to
  /// @param token is the address of the ERC20 token that is locked in vesting plans and has been delegated
  function delegatedBalances(address delegatee, address token) external view returns (uint256 delegatedBalance) {
    uint256 delegateBalance = balanceOfDelegate(delegatee);
    for (uint256 i; i < delegateBalance; i++) {
      uint256 planId = tokenOfDelegateByIndex(delegatee, i);
      Plan memory plan = plans[planId];
      if (token == plan.token) {
        delegatedBalance += plan.amount;
      }
    }
  }

  /****NFT FRANSFER SPECIAL FUNCTIONS*********************************************************************************************************************************************/

  /// @notice a function for the owner of a vesting plan to toggle on or off the adminTransferOBO boolean
  /// @param planId is the id of the vesting plan
  /// @param transferrable is the boolean true or false that updates the plan struct for adminTransferOBO
  function toggleAdminTransferOBO(uint256 planId, bool transferrable) external nonReentrant {
    require(msg.sender == ownerOf(planId), '!owner');
    plans[planId].adminTransferOBO = transferrable;
    emit PlanVestingAdminTransferToggle(planId, transferrable);
  }

  ///  @notice special function to transfer an NFT that overrides the normal ERC721 transferFrom function.
  /// this function lets a vestingAdmin of a plan transfer the NFT on behalf of a the holder of an NFT.
  /// the vesting plan must have the adminTransferOBO toggle turned on to true for this function to be called.
  /// this functin cannot be called by the owner / beneficiary of the NFT and vesting plan.
  /// the to address cannot be the vestingAdmin address
  ///  @param from is the address the NFT and plan is transferred from
  ///  @param to is the address where the NFT and plan is being transferred to
  ///  @param tokenId is the NFT tokenID, the same as the planId to be transferred
  function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) {
    require(plans[tokenId].adminTransferOBO, '!transferrable');
    require(to != plans[tokenId].vestingAdmin, '!transfer to admin');
    require(msg.sender == plans[tokenId].vestingAdmin, '!vestingAdmin');
    _transfer(from, to, tokenId);
    emit PlanTransferredByVestingAdmin(tokenId, from, to);
  }

  /// @notice vesting plans are not transferable, with the exception of the above method.
  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal override {
    revert('!transferrable');
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '../sharedContracts/PlanDelegator.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../libraries/TransferHelper.sol';
import '../libraries/TimelockLibrary.sol';
import '../sharedContracts/VotingVault.sol';
import '../sharedContracts/URIAdmin.sol';
import '../sharedContracts/VestingStorage.sol';

/// @title VotingTokenVestingPlans - An efficient way to allocate tokens to employees that vest over time
/// @notice This contract allows people to grant tokens to beneficiaries that vest over time with the added functionalities;
/// Each vesting plan is a unique NFT, leveraging the backbone of the ERC721 contract to represent a unique vesting plan
/// 1. Revokable: plans can be revoked and unvested tokens returned to the company (vesting admin)
/// 2. Soul Bound: plans are by default soul bound and not transferable, however can be transferred by an admin in emergencies
/// 3. Governance optimized for on-chain voting: These are built to allow beneficiaries to vote with their unvested tokens on chain with the standard ERC20Votes contract, as well as on snapshot
/// 4. Beneficiary Claims: Beneficiaries get to choose when to claim their tokens, and can claim partial amounts that are less than the amount they vested for tax optimization

contract VotingTokenVestingPlans is PlanDelegator, VestingStorage, ReentrancyGuard, URIAdmin {
  /// @notice uses counters for incrementing token IDs which are the planIds
  using Counters for Counters.Counter;
  Counters.Counter private _planIds;

  /// @dev Voting Vaults are external contracts that hold tokens for a vesting plan allowing an owner to delegate their tokens for on-chain governance
  /// the vesting plan ID is mapped to the votingVault address so that it is one to one and unique to the NFT
  mapping(uint256 => address) public votingVaults;

  /// @notice event emitted when a new voting vault is generated and setup
  event VotingVaultCreated(uint256 indexed id, address vaultAddress);

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    uriAdmin = msg.sender;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /****CORE EXTERNAL FUNCTIONS*********************************************************************************************************************************************/

  /// @notice function to create a vesting plan.
  /// @dev this function will pull the tokens into this contract for escrow, increment the planIds, mint an NFT to the recipient, and create the storage Plan and map it to the newly minted NFT token ID in storage
  /// @param recipient the address of the recipient and beneficiary of the plan
  /// @param token the address of the ERC20 token
  /// @param amount the amount of tokens to be locked in the plan
  /// @param start the start date of the vesting plan, unix time
  /// @param cliff a cliff date which is a discrete date where tokens are not vested until this date, and then vest in a large single chunk on the cliff date
  /// @param rate the amount of tokens that vest in a single period
  /// @param period the amount of time in between each vesting time stamp, in seconds. A period of 1 means that tokens vest every second in a 'streaming' style.
  /// @param vestingAdmin is the address of an administrator in charge of revoking the plan, pulling back any unvested tokens to the vestingAdmin address
  /// @param adminTransferOBO is an optional toggle to allow the vestingAdmin to transfer a plan and NFT to another wallet on behalf of (OBO) a beneficiary. To be used only for emergencies.
  function createPlan(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 rate,
    uint256 period,
    address vestingAdmin,
    bool adminTransferOBO
  ) external nonReentrant returns (uint256 newPlanId) {
    require(recipient != address(0), '0_recipient');
    require(token != address(0), '0_token');
    (uint256 end, bool valid) = TimelockLibrary.validateEnd(start, cliff, amount, rate, period);
    require(valid);
    _planIds.increment();
    newPlanId = _planIds.current();
    TransferHelper.transferTokens(token, msg.sender, address(this), amount);
    plans[newPlanId] = Plan(token, amount, start, cliff, rate, period, vestingAdmin, adminTransferOBO);
    _safeMint(recipient, newPlanId);
    emit PlanCreated(
      newPlanId,
      recipient,
      token,
      amount,
      start,
      cliff,
      end,
      rate,
      period,
      vestingAdmin,
      adminTransferOBO
    );
  }

  /// @notice function for a beneficiary to redeem vested tokens from a group of plans
  /// @dev this will call an internal function for processing the actual redemption of tokens, which will withdraw vested tokens and deliver them to the beneficiary
  /// @dev this function will redeem all claimable and vested tokens up to the current block.timestamp
  /// @param planIds is the array of the NFT planIds that are to be redeemed. If any have no redeemable balance they will be skipped.
  function redeemPlans(uint256[] calldata planIds) external nonReentrant {
    _redeemPlans(planIds, block.timestamp);
  }

  /// @notice function for a beneficiary to redeem vested tokens from a group of plans
  /// @dev this will call an internal function for processing the actual redemption of tokens, which will withdraw vested tokens and deliver them to the beneficiary
  /// @dev this function will redeem only a partial amount of tokens based on a redemption timestamp that is in the past. This allows holders to redeem less than their fully vested amount for various reasons
  /// @param planIds is the array of the NFT planIds that are to be redeemed. If any have no redeemable balance they will be skipped.
  /// @param redemptionTime is the timestamp which will calculate the amount of tokens redeemable and redeem them based on that timestamp
  function partialRedeemPlans(uint256[] calldata planIds, uint256 redemptionTime) external nonReentrant {
    require(redemptionTime < block.timestamp, '!future');
    _redeemPlans(planIds, redemptionTime);
  }

  /// @notice this function will redeem all plans owned by a single wallet - useful for custodians or other intermeidaries that do not have the ability to lookup individual planIds
  /// @dev this will iterate through all of the plans owned by the wallet based on the ERC721Enumerable backbone, and redeem each one with a redemption time of the current block.timestamp
  function redeemAllPlans() external nonReentrant {
    uint256 balance = balanceOf(msg.sender);
    uint256[] memory planIds = new uint256[](balance);
    for (uint256 i; i < balance; i++) {
      uint256 planId = tokenOfOwnerByIndex(msg.sender, i);
      planIds[i] = planId;
    }
    _redeemPlans(planIds, block.timestamp);
  }

  /// @notice the function for a vestingAdmin to revoke vesting plans.
  /// @dev this will call an internal function to revoke plans, whereby unvested tokens will be returned to the vestingAdmin, and any tokens that are vested will be delivered to the beneficiary(s)
  /// @param planIds is the array of the plan ids to be redeemed. the caller must be the vesting admin for all of the plans.
  function revokePlans(uint256[] calldata planIds) external nonReentrant {
    for (uint256 i; i < planIds.length; i++) {
      _revokePlan(planIds[i], block.timestamp);
    }
  }

  /// @notice this function allows a vesting admin to revoke a plan with a future date
  /// @dev different than the revokePlans function this takes an input time that is used for all of the plan revoking, which must be at least the current time stamp or future
  /// @param planIds is the array of the plan ids to be redeemed. the caller must be the vesting admin for all of the plans.
  /// @param revokeTime is the future time which the plans will be revoked effectively at
  function futureRevokePlans(uint256[] calldata planIds, uint256 revokeTime) external nonReentrant {
    require(revokeTime >= block.timestamp, '!past revoke');
    for (uint256 i; i < planIds.length; i++) {
      _revokePlan(planIds[i], revokeTime);
    }
  }

  /// @notice the function for a vestingAdmin to assing a new vestingAdmin wallet for a specific plan. Used in emergencies where DAOs are changing multi-sigs or other events
  /// @dev the new vesting admin address cannot be the beneficiary of the plan
  /// @param planId is the NFT token id of the plan
  /// @param newVestingAdmin is the address which the vesting admin of the plan will be assigned
  function changeVestingPlanAdmin(uint256 planId, address newVestingAdmin) external {
    Plan storage plan = plans[planId];
    require(msg.sender == plan.vestingAdmin, '!vestingAdmin');
    require(ownerOf(planId) != newVestingAdmin, '!planOwner');
    plan.vestingAdmin = newVestingAdmin;
    emit VestingPlanAdminChanged(planId, newVestingAdmin);
  }

  /****EXTERNAL VOTING & DELGATION FUNCTIONS*********************************************************************************************************************************************/
  /// @notice functions for the owners of vesting plans to setup on chain voting vaults, and then delegate those tokens.
  /// these are explicity for tokens that are of the ERC20Votes format, which have a delegate and delegates function.
  /// tokens that do not have the standard delegate and delegates functionality for on-chain voting will revert when delegating or creating onchain voting vaults.

  /// @notice function to setup a voting vault, this calls an internal voting function to set it up
  /// @param planId is the id of the vesting plan and NFT
  function setupVoting(uint256 planId) external nonReentrant returns (address votingVault) {
    votingVault = _setupVoting(planId);
  }

  /// @notice function for an owner of a vesting plan to delegate a single vesting plan to  single delegate
  /// @dev this will call an internal delegate function for processing
  /// if there is no voting vault setup, this function will automatically create a voting vault and then delegate the tokens to the delegatee
  /// @param planId is the id of the vesting plan and NFT
  function delegate(uint256 planId, address delegatee) external nonReentrant {
    _delegate(planId, delegatee);
  }

  /// @notice this function allows an owner of multiple vesting plans to delegate multiple of them in a single transaction, each planId corresponding to a delegatee address
  /// @param planIds is the ids of the vesting plan and NFT
  /// @param delegatees is the array of addresses where each vesting plan will delegate the tokens to
  function delegatePlans(uint256[] calldata planIds, address[] calldata delegatees) external nonReentrant {
    require(planIds.length == delegatees.length, 'array error');
    for (uint256 i; i < planIds.length; i++) {
      _delegate(planIds[i], delegatees[i]);
    }
  }

  /// @notice this function lets an owner delegate all of their vesting plans for a single token to a single delegatee
  /// @dev this function will iterate through all of the owned vesting plans of the msg.sender, and if the token address matches the vesting plan token address, it will delegate that plan
  /// @param token is the ERC20Votes token address that the owner is vesting
  /// @param delegatee is the address of the delegate that the beneficiary is delegating their tokens to
  function delegateAll(address token, address delegatee) external nonReentrant {
    uint256 balance = balanceOf(msg.sender);
    for (uint256 i; i < balance; i++) {
      uint256 planId = tokenOfOwnerByIndex(msg.sender, i);
      if (plans[planId].token == token) _delegate(planId, delegatee);
    }
  }

  /****CORE INTERNAL FUNCTIONS*********************************************************************************************************************************************/

  /// @notice function that will intake an array of planIds and a redemption time, and then check the balances that are available to be redeemed
  /// @dev if the nft has an available balance, it is then passed on to the _redeemPlan function for further processing
  /// if there is no balance to be redeemed, the plan is skipped from being processed
  /// @param planIds is the array of plans to be redeemed
  /// @param redemptionTime is the requested redemption time, either the current block.timestamp or a timestamp from the past, but must be greater than the start date
  function _redeemPlans(uint256[] memory planIds, uint256 redemptionTime) internal {
    for (uint256 i; i < planIds.length; i++) {
      (uint256 balance, uint256 remainder, uint256 latestUnlock) = planBalanceOf(
        planIds[i],
        block.timestamp,
        redemptionTime
      );
      if (balance > 0) _redeemPlan(planIds[i], balance, remainder, latestUnlock);
    }
  }

  /// @notice internal function that process the redemption for a single vesting plan
  /// @dev this takes the inputs from the _redeemPlans and processes the redemption delivering the available balance of redeemable tokens to the beneficiary
  /// If the tokens are held in an external voting vault, then tokens are withdrawn from the voting vault, rather than transferred from this contract
  /// if the plan is fully redeemed, as defined that the balance == amount, then the plan is deleted and NFT burned
  /// if the plan is not fully redeemed, then the storage of start and amount are updated to reflect the remaining amount and most recent time redeemed for the new start date
  /// @param planId is the id of the vesting plan and NFT
  /// @param balance is the available redeemable balance
  /// @param remainder is the amount of tokens that are still unvested in the plan, and will be the new amount in the plan storage
  /// @param latestUnlock is the most recent timestamp for when redemption occured. Because periods may be longer than 1 second, the latestUnlock time may be the current block time, or the timestamp of the most recent period timestamp
  function _redeemPlan(uint256 planId, uint256 balance, uint256 remainder, uint256 latestUnlock) internal {
    require(ownerOf(planId) == msg.sender, '!owner');
    address token = plans[planId].token;
    address vault = votingVaults[planId];
    if (remainder == 0) {
      delete plans[planId];
      delete votingVaults[planId];
      _burn(planId);
    } else {
      plans[planId].amount = remainder;
      plans[planId].start = latestUnlock;
    }
    if (vault == address(0)) {
      TransferHelper.withdrawTokens(token, msg.sender, balance);
    } else {
      VotingVault(vault).withdrawTokens(msg.sender, balance);
    }
    emit PlanRedeemed(planId, balance, remainder, latestUnlock);
  }

  /// @notice the internal function to revoke a vesting plan
  /// @dev this is called by the external revokePlans function, which inputs the msg.sender as the vestingAdmin and the planId from the inputs
  /// this function checks that the vestingAdmin is the vestingAdmin, and that there is actually a revokable balance.
  /// The function then withdraws the unvested tokens that are revoked, delivering them to the vestingAdmin
  /// the function will not automatically transfer the tokens to the plan beneficiary.
  /// If the vesting plan has no balance left, because the remainder is the entire amount then it will be burned and deleted
  /// otherwise the NFT will still exist, but the amount is set to the balance that is still to be vested so it can vest along the same time as its original vesting terms
  /// but the vestingAdmin is set to 0 address so that it cannot be revoked again or transferred
  /// if the plan has an external voting vault setup, then tokens will be withdrawn from the voting vault rather than this contract address
  /// finally the function deletes the plan held in storage and burns the NFT.
  /// @param planId is the id of the plan and NFT
  /// @param revokeTime is the time that the plan will be revoked effectively at, which can be in the future but not the past
  function _revokePlan(uint256 planId, uint256 revokeTime) internal {
    Plan memory plan = plans[planId];
    require(msg.sender == plan.vestingAdmin, '!vestingAdmin');
    (uint256 balance, uint256 remainder, ) = planBalanceOf(planId, block.timestamp, revokeTime);
    require(remainder > 0, '!Remainder');
    if (balance == 0) {
      delete plans[planId];
      _burn(planId);
      delete votingVaults[planId];
    } else {
      plans[planId].amount = balance;
      plans[planId].vestingAdmin = address(0);
    }
    address vault = votingVaults[planId];
    if (vault == address(0)) {
      TransferHelper.withdrawTokens(plan.token, msg.sender, remainder);
    } else {
      VotingVault(vault).withdrawTokens(msg.sender, remainder);
    }
    emit PlanRevoked(planId, balance, remainder);
  }

  /****INTERNAL VOTING FUNCTIONS*********************************************************************************************************************************************/

  /// @notice the internal function to setup a voting vault.
  /// @dev this will check that no voting vault exists already and then deploy a new voting vault contract
  // during the constructor setup of the voting vault, it will auto delegate the voting vault address to whatever the existing delegate of the vesting plan holder has delegated to
  // if it has not delegated yet, it will self-delegate the tokens
  /// then transfer the tokens remaining in the vesting plan to the voting vault physically
  /// @param planId is the id of the vesting plan and NFT
  function _setupVoting(uint256 planId) internal returns (address) {
    require(_isApprovedDelegatorOrOwner(msg.sender, planId), '!delegator');
    require(votingVaults[planId] == address(0), 'exists');
    Plan memory plan = plans[planId];
    VotingVault vault = new VotingVault(plan.token, ownerOf(planId));
    votingVaults[planId] = address(vault);
    TransferHelper.withdrawTokens(plan.token, address(vault), plan.amount);
    emit VotingVaultCreated(planId, address(vault));
    return address(vault);
  }

  /// @notice this internal function will physically delegate tokens held in a voting vault to a delegatee
  /// @dev if a voting vautl has not been setup yet, then the function will call the internal _setupVoting function and setup a new voting vault
  /// and then it will delegate the tokens held in the vault to the delegatee
  /// @param planId is the id of the vesting plan and NFT
  /// @param delegatee is the address of the delegatee where the tokens in the voting vault will be delegated to
  function _delegate(uint256 planId, address delegatee) internal {
    require(_isApprovedDelegatorOrOwner(msg.sender, planId), '!delegator');
    address vault = votingVaults[planId];
    if (votingVaults[planId] == address(0)) {
      vault = _setupVoting(planId);
    }
    VotingVault(vault).delegateTokens(delegatee);
  }

  /****VIEW VOTING FUNCTIONS*********************************************************************************************************************************************/

  /// @notice this function will pull all of the unclaimed tokens for a specific holder across all of their plans, based on a single ERC20 token
  /// very useful for snapshot voting, and other view functionalities. This aggregates all balances, including any in voting vaults.
  /// @param holder is the address of the beneficiary who owns the vesting plan(s)
  /// @param token is the ERC20 address of the token that is stored across the vesting plans
  function lockedBalances(address holder, address token) external view returns (uint256 lockedBalance) {
    uint256 holdersBalance = balanceOf(holder);
    for (uint256 i; i < holdersBalance; i++) {
      uint256 planId = tokenOfOwnerByIndex(holder, i);
      Plan memory plan = plans[planId];
      if (token == plan.token) {
        lockedBalance += plan.amount;
      }
    }
  }

  /****NFT FRANSFER SPECIAL FUNCTIONS*********************************************************************************************************************************************/

  /// @notice a function for the owner of a vesting plan to toggle on or off the adminTransferOBO boolean
  /// @param planId is the id of the vesting plan
  /// @param transferrable is the boolean true or false that updates the plan struct for adminTransferOBO
  function toggleAdminTransferOBO(uint256 planId, bool transferrable) external nonReentrant {
    require(msg.sender == ownerOf(planId), '!owner');
    plans[planId].adminTransferOBO = transferrable;
    emit PlanVestingAdminTransferToggle(planId, transferrable);
  }

  /// @notice special function to transfer an NFT that overrides the normal ERC721 transferFrom function.
  /// this function lets a vestingAdmin of a plan transfer the NFT on behalf of a the holder of an NFT.
  /// the vesting plan must have the adminTransferOBO toggle turned on to true for this function to be called.
  /// this functin cannot be called by the owner / beneficiary of the NFT and vesting plan.
  /// the to address cannot be the vestingAdmin address
  ///  @param from is the address the NFT and plan is transferred from
  ///  @param to is the address where the NFT and plan is being transferred to
  ///  @param tokenId is the NFT tokenID, the same as the planId to be transferred
  function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) {
    require(plans[tokenId].adminTransferOBO, '!transferrable');
    require(to != plans[tokenId].vestingAdmin, '!transfer to admin');
    require(msg.sender == plans[tokenId].vestingAdmin, '!vestingAdmin');
    _transfer(from, to, tokenId);
    emit PlanTransferredByVestingAdmin(tokenId, from, to);
  }

  /// @notice vesting plans are not transferable, with the exception of the above method.
  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal override {
    revert('!transferrable');
  }
}