// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
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
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
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
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
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
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

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
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

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
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ILendingVault {

  /* ======================= STRUCTS ========================= */

  struct Borrower {
    // Boolean for whether borrower is approved to borrow from this vault
    bool approved;
    // Debt share of the borrower in this vault
    uint256 debt;
    // The last timestamp borrower borrowed from this vault
    uint256 lastUpdatedAt;
  }

  struct InterestRate {
    // Base interest rate which is the y-intercept when utilization rate is 0 in 1e18
    uint256 baseRate;
    // Multiplier of utilization rate that gives the slope of the interest rate in 1e18
    uint256 multiplier;
    // Multiplier after hitting a specified utilization point (kink2) in 1e18
    uint256 jumpMultiplier;
    // Utilization point at which the interest rate is fixed in 1e18
    uint256 kink1;
    // Utilization point at which the jump multiplier is applied in 1e18
    uint256 kink2;
  }

  function totalAsset() external view returns (uint256);
  function totalAvailableAsset() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function lvTokenValue() external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxRepay(address borrower) external view returns (uint256);
  function depositNative(uint256 assetAmt, uint256 minSharesAmt) payable external;
  function deposit(uint256 assetAmt, uint256 minSharesAmt) external;
  function withdraw(uint256 sharesAmt, uint256 minAssetAmt) external;
  function borrow(uint256 assetAmt) external;
  function repay(uint256 repayAmt) external;
  function withdrawReserve(uint256 assetAmt) external;
  function updatePerformanceFee(uint256 newPerformanceFee) external;
  function updateInterestRate(InterestRate memory newInterestRate) external;
  function approveBorrower(address borrower) external;
  function revokeBorrower(address borrower) external;
  function updateKeeper(address keeper, bool approval) external;
  function emergencyRepay(uint256 repayAmt, address defaulter) external;
  function emergencyShutdown() external;
  function emergencyResume() external;
  function updateMaxCapacity(uint256 newMaxCapacity) external;
  function updateMaxInterestRate(InterestRate memory newMaxInterestRate) external;
  function updateTreasury(address newTreasury) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IWNT {
  function balanceOf(address user) external returns (uint);
  function approve(address to, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function deposit() external payable;
  function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ILendingVault } from "../interfaces/lending/ILendingVault.sol";
import { IWNT } from "../interfaces/tokens/IWNT.sol";
import { Errors } from "../utils/Errors.sol";

// import "forge-std/console.sol";

contract LendingVault is ERC20, ReentrancyGuard, Pausable, Ownable2Step, ILendingVault {
  using SafeERC20 for IERC20;

  /* ====================== CONSTANTS ======================== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;
  uint256 public constant SECONDS_PER_YEAR = 365 days;

  /* ==================== STATE VARIABLES ==================== */

  // Vault's underlying asset
  IERC20 public asset;
  // Is asset native ETH
  bool public isNativeAsset;
  // Protocol treasury address
  address public treasury;
  // Amount borrowed from this vault
  uint256 public totalBorrows;
  // Total borrow shares in this vault
  uint256 public totalBorrowDebt;
  // The fee % applied to interest earned that goes to the protocol in 1e18
  uint256 public performanceFee;
  // Protocol earnings reserved in this vault
  uint256 public vaultReserves;
  // Last updated timestamp of this vault
  uint256 public lastUpdatedAt;
  // Max capacity of vault in asset decimals / amt
  uint256 public maxCapacity;
  // Interest rate model
  InterestRate public interestRate;
  // Max interest rate model limits
  InterestRate public maxInterestRate;

  /* ======================= MAPPINGS ======================== */

  // Mapping of borrowers to borrowers struct
  mapping(address => Borrower) public borrowers;
  // Mapping of approved keepers
  mapping(address => bool) public keepers;

  /* ======================== EVENTS ========================= */

  event Deposit(address indexed depositor, uint256 sharesAmt, uint256 depositAmt);
  event Withdraw(address indexed withdrawer, uint256 sharesAmt, uint256 withdrawAmt);
  event Borrow(address indexed borrower, uint256 borrowDebt, uint256 borrowAmt);
  event Repay(address indexed borrower, uint256 repayDebt, uint256 repayAmt);
  event PerformanceFeeUpdated(
    address indexed caller,
    uint256 previousPerformanceFee,
    uint256 newPerformanceFee
  );
  event UpdateMaxCapacity(uint256 maxCapacity);
  event EmergencyShutdown(address indexed caller);
  event EmergencyResume(address indexed caller);
  event UpdateInterestRate(
    uint256 baseRate,
    uint256 multiplier,
    uint256 jumpMultiplier,
    uint256 kink1,
    uint256 kink2
  );
  event UpdateMaxInterestRate(
    uint256 baseRate,
    uint256 multiplier,
    uint256 jumpMultiplier,
    uint256 kink1,
    uint256 kink2
  );

  /* ======================= MODIFIERS ======================= */

  /**
    * @notice Allow only approved borrower addresses
  */
  modifier onlyBorrower() {
    _onlyBorrower();
    _;
  }

  /**
    * @notice Allow only keeper addresses
  */
  modifier onlyKeeper() {
    _onlyKeeper();
    _;
  }

  /* ====================== CONSTRUCTOR ====================== */

  /**
    * @param _name  Name for this lending vault, e.g. Interest Bearing AVAX
    * @param _symbol  Symbol for this lending vault, e.g. ibAVAX-AVAXUSDC-GMX
    * @param _asset  Contract address for underlying ERC20 asset
    * @param _isNativeAsset  Whether vault asset is native or not
    * @param _performanceFee  Performance fee in 1e18
    * @param _maxCapacity Max capacity of lending vault in asset decimals
    * @param _treasury  Contract address for protocol treasury
    * @param _interestRate  InterestRate struct initial
    * @param _maxInterestRate  InterestRate struct for max interest rates
  */
  constructor(
    string memory _name,
    string memory _symbol,
    IERC20 _asset,
    bool _isNativeAsset,
    uint256 _performanceFee,
    uint256 _maxCapacity,
    address _treasury,
    InterestRate memory _interestRate,
    InterestRate memory _maxInterestRate
  ) ERC20(_name, _symbol) Ownable(msg.sender) {
    if (address(_asset) == address(0)) revert Errors.ZeroAddressNotAllowed();
    if (_treasury == address(0)) revert Errors.ZeroAddressNotAllowed();
    if (ERC20(address(_asset)).decimals() > 18) revert Errors.TokenDecimalsMustBeLessThan18();

    asset = _asset;
    isNativeAsset = _isNativeAsset;
    performanceFee = _performanceFee;
    maxCapacity = _maxCapacity;
    treasury = _treasury;

    interestRate.baseRate = _interestRate.baseRate;
    interestRate.multiplier = _interestRate.multiplier;
    interestRate.jumpMultiplier = _interestRate.jumpMultiplier;
    interestRate.kink1 = _interestRate.kink1;
    interestRate.kink2 = _interestRate.kink2;

    maxInterestRate.baseRate = _maxInterestRate.baseRate;
    maxInterestRate.multiplier = _maxInterestRate.multiplier;
    maxInterestRate.jumpMultiplier = _maxInterestRate.jumpMultiplier;
    maxInterestRate.kink1 = _maxInterestRate.kink1;
    maxInterestRate.kink2 = _maxInterestRate.kink2;
  }

  /* ===================== VIEW FUNCTIONS ==================== */

  /**
    * @notice Returns the total value of the lending vault, i.e totalBorrows + interest + totalAvailableAsset
    * @return totalAsset   Total value of lending vault in token decimals
  */
  function totalAsset() public view returns (uint256) {
    return totalBorrows + _pendingInterest(0) + totalAvailableAsset();
  }

  /**
    * @notice Returns the available balance of asset in the vault that is borrowable
    * @return totalAvailableAsset   Balance of asset in the vault in token decimals
  */
  function totalAvailableAsset() public view returns (uint256) {
    return asset.balanceOf(address(this));
  }

  /**
    * @notice Returns the the borrow utilization rate of the vault
    * @return utilizationRate   Ratio of borrows to total liquidity in 1e18
  */
  function utilizationRate() public view returns (uint256){
    uint256 totalAsset_ = totalAsset();

    return (totalAsset_ == 0) ? 0 : totalBorrows * SAFE_MULTIPLIER / totalAsset_;
  }

  /**
    * @notice Returns the exchange rate for lvToken to asset
    * @return lvTokenValue   Ratio of lvToken to underlying asset in token decimals
  */
  function lvTokenValue() public view returns (uint256) {
    uint256 totalAsset_ = totalAsset();
    uint256 totalSupply_ = totalSupply();

    if (totalAsset_ == 0 || totalSupply_ == 0) {
      return 1 * (10 ** ERC20(address(asset)).decimals());
    } else {
      return totalAsset_ * SAFE_MULTIPLIER / totalSupply_;
    }
  }

  /**
    * @notice Returns the current borrow APR
    * @return borrowAPR   Current borrow rate in 1e18
  */
  function borrowAPR() public view returns (uint256) {
    return _calculateInterestRate(totalBorrows, totalAvailableAsset());
  }

  /**
    * @notice Returns the current lending APR; borrowAPR * utilization * (1 - performanceFee)
    * @return lendingAPR   Current lending rate in 1e18
  */
  function lendingAPR() public view returns (uint256) {
    uint256 borrowAPR_ = borrowAPR();
    uint256 utilizationRate_ = utilizationRate();

    if (borrowAPR_ == 0 || utilizationRate_ == 0) {
      return 0;
    } else {
      return borrowAPR_ * utilizationRate_
                         / SAFE_MULTIPLIER
                         * ((1 * SAFE_MULTIPLIER) - performanceFee)
                         / SAFE_MULTIPLIER;
    }
  }

  /**
    * @notice Returns a borrower's maximum total repay amount taking into account ongoing interest
    * @param borrower   Borrower's address
    * @return maxRepay   Borrower's total repay amount of assets in assets decimals
  */
  function maxRepay(address borrower) public view returns (uint256) {
    if (totalBorrows == 0) {
      return 0;
    } else {
      return borrowers[borrower].debt * (totalBorrows + _pendingInterest(0)) / totalBorrowDebt;
    }
  }

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @notice Deposits native asset into lending vault and mint shares to user
    * @param assetAmt Amount of asset tokens to deposit in token decimals
    * @param minSharesAmt Minimum amount of lvTokens tokens to receive on deposit
  */
  function depositNative(uint256 assetAmt, uint256 minSharesAmt) payable public nonReentrant whenNotPaused {
    if (msg.value <= 0) revert Errors.EmptyDepositAmount();
    if (assetAmt != msg.value) revert Errors.InvalidNativeDepositAmountValue();
    if (assetAmt + totalAsset() > maxCapacity) revert Errors.InsufficientCapacity();
    if (assetAmt <= 0) revert Errors.InsufficientDepositAmount();

    IWNT(address(asset)).deposit{ value: msg.value }();

    // Update vault with accrued interest and latest timestamp
    _updateVaultWithInterestsAndTimestamp(assetAmt);

    uint256 _sharesAmount = _mintShares(assetAmt);

    if (_sharesAmount < minSharesAmt) revert Errors.InsufficientSharesMinted();

    emit Deposit(msg.sender, _sharesAmount, assetAmt);
  }

  /**
    * @notice Deposits asset into lending vault and mint shares to user
    * @param assetAmt Amount of asset tokens to deposit in token decimals
    * @param minSharesAmt Minimum amount of lvTokens tokens to receive on deposit
  */
  function deposit(uint256 assetAmt, uint256 minSharesAmt) public nonReentrant whenNotPaused {
    if (assetAmt + totalAsset() > maxCapacity) revert Errors.InsufficientCapacity();
    if (assetAmt <= 0) revert Errors.InsufficientDepositAmount();

    asset.safeTransferFrom(msg.sender, address(this), assetAmt);

    // Update vault with accrued interest and latest timestamp
    _updateVaultWithInterestsAndTimestamp(assetAmt);

    uint256 _sharesAmount = _mintShares(assetAmt);

    if (_sharesAmount < minSharesAmt) revert Errors.InsufficientSharesMinted();

    emit Deposit(msg.sender, _sharesAmount, assetAmt);
  }

  /**
    * @notice Withdraws asset from lending vault, burns lvToken from user
    * @param sharesAmt Amount of lvTokens to burn in 1e18
    * @param minAssetAmt Minimum amount of asset tokens to receive on withdrawal
  */
  function withdraw(uint256 sharesAmt, uint256 minAssetAmt) public nonReentrant whenNotPaused {
    if (sharesAmt <= 0) revert Errors.InsufficientWithdrawAmount();
    if (sharesAmt > balanceOf(msg.sender)) revert Errors.InsufficientWithdrawBalance();

    // Update vault with accrued interest and latest timestamp
    _updateVaultWithInterestsAndTimestamp(0);

    uint256 _assetAmt = _burnShares(sharesAmt);

    if (_assetAmt > totalAvailableAsset()) revert Errors.InsufficientAssetsBalance();
    if (_assetAmt < minAssetAmt) revert Errors.InsufficientAssetsReceived();

    if (isNativeAsset) {
      IWNT(address(asset)).withdraw(_assetAmt);
      (bool success, ) = msg.sender.call{value: _assetAmt}("");
      require(success, "Transfer failed.");
    } else {
      asset.safeTransfer(msg.sender, _assetAmt);
    }

    emit Withdraw(msg.sender, sharesAmt, _assetAmt);
  }

  /**
    * @notice Borrow asset from lending vault, adding debt
    * @param borrowAmt Amount of tokens to borrow in token decimals
  */
  function borrow(uint256 borrowAmt) external nonReentrant whenNotPaused onlyBorrower {
    if (borrowAmt <= 0) revert Errors.InsufficientBorrowAmount();
    if (borrowAmt > totalAvailableAsset()) revert Errors.InsufficientLendingLiquidity();

    // Update vault with accrued interest and latest timestamp
    _updateVaultWithInterestsAndTimestamp(0);

    // Calculate debt amount
    uint256 _debt = totalBorrows == 0 ? borrowAmt : borrowAmt * totalBorrowDebt / totalBorrows;

    // Update vault state
    totalBorrows = totalBorrows + borrowAmt;
    totalBorrowDebt = totalBorrowDebt + _debt;

    // Update borrower state
    Borrower storage borrower = borrowers[msg.sender];
    borrower.debt = borrower.debt + _debt;
    borrower.lastUpdatedAt = block.timestamp;

    // Transfer borrowed token from vault to manager
    asset.safeTransfer(msg.sender, borrowAmt);

    emit Borrow(msg.sender, _debt, borrowAmt);
  }

  /**
    * @notice Repay asset to lending vault, reducing debt
    * @param repayAmt Amount of debt to repay in token decimals
  */
  function repay(uint256 repayAmt) external nonReentrant {
    if (repayAmt <= 0) revert Errors.InsufficientRepayAmount();
    // Update vault with accrued interest and latest timestamp
    _updateVaultWithInterestsAndTimestamp(0);

    uint256 maxRepay_ = maxRepay(msg.sender);
    if (maxRepay_ > 0) {
      if (repayAmt > maxRepay_) {
        repayAmt = maxRepay_;
      }

      // Calculate debt to reduce based on repay amount
      uint256 _debt = repayAmt * borrowers[msg.sender].debt / maxRepay_;

      // Update vault state
      totalBorrows = totalBorrows - repayAmt;
      totalBorrowDebt = totalBorrowDebt - _debt;

      // Update borrower state
      borrowers[msg.sender].debt = borrowers[msg.sender].debt - _debt;
      borrowers[msg.sender].lastUpdatedAt = block.timestamp;

      // Transfer repay tokens to the vault
      asset.safeTransferFrom(msg.sender, address(this), repayAmt);

      emit Repay(msg.sender, _debt, repayAmt);
    }
  }

  /**
  * @notice Withdraw protocol fees from reserves to treasury
  * @param assetAmt  Amount to withdraw in token decimals
  */
  function withdrawReserve(uint256 assetAmt) external nonReentrant onlyKeeper {
    // Update vault with accrued interest and latest timestamp
    _updateVaultWithInterestsAndTimestamp(0);

    if (assetAmt > vaultReserves) assetAmt = vaultReserves;

    unchecked {
      vaultReserves = vaultReserves - assetAmt;
    }

    asset.safeTransfer(treasury, assetAmt);
  }

  /* ================== INTERNAL FUNCTIONS =================== */

  /**
    * @notice Allow only approved borrower addresses
  */
  function _onlyBorrower() internal view {
    if (!borrowers[msg.sender].approved) revert Errors.OnlyBorrowerAllowed();
  }

  /**
    * @notice Allow only keeper addresses
  */
  function _onlyKeeper() internal view {
    if (!keepers[msg.sender]) revert Errors.OnlyKeeperAllowed();
  }

  /**
    * @notice Calculate amount of lvTokens owed to depositor and mints them
    * @param assetAmt  Amount of asset to deposit in token decimals
    * @return shares  Amount of lvTokens minted in 1e18
  */
  function _mintShares(uint256 assetAmt) internal returns (uint256) {
    uint256 _shares;

    if (totalSupply() == 0) {
      _shares = assetAmt * _to18ConversionFactor();
    } else {
      _shares = assetAmt * totalSupply() / (totalAsset() - assetAmt);
    }

    // Mint lvToken to user equal to liquidity share amount
    _mint(msg.sender, _shares);

    return _shares;
  }

  /**
    * @notice Calculate amount of asset owed to depositor based on lvTokens burned
    * @param sharesAmt Amount of shares to burn in 1e18
    * @return withdrawAmount  Amount of assets withdrawn based on lvTokens burned in token decimals
  */
  function _burnShares(uint256 sharesAmt) internal returns (uint256) {
    // Calculate amount of assets to withdraw based on shares to burn
    uint256 totalSupply_ = totalSupply();
    uint256 _withdrawAmount = totalSupply_ == 0 ? 0 : sharesAmt * totalAsset() / totalSupply_;

    // Burn user's lvTokens
    _burn(msg.sender, sharesAmt);

    return _withdrawAmount;
  }

  /**
    * @notice Interest accrual function that calculates accumulated interest from lastUpdatedTimestamp and add to totalBorrows
    * @param assetAmt Additonal amount of assets being deposited in token decimals
  */
  function _updateVaultWithInterestsAndTimestamp(uint256 assetAmt) internal {
    uint256 _interest = _pendingInterest(assetAmt);
    uint256 _toReserve = _interest * performanceFee / SAFE_MULTIPLIER;

    vaultReserves = vaultReserves + _toReserve;
    totalBorrows = totalBorrows + _interest;
    lastUpdatedAt = block.timestamp;
  }

  /**
    * @notice Returns the pending interest that will be accrued to the reserves in the next call
    * @param assetAmt Newly deposited assets to be subtracted off total available liquidity in token decimals
    * @return interest  Amount of interest owned in token decimals
  */
  function _pendingInterest(uint256 assetAmt) internal view returns (uint256) {
    if (totalBorrows == 0) return 0;

    uint256 totalAvailableAsset_ = totalAvailableAsset();
    uint256 _timePassed = block.timestamp - lastUpdatedAt;
    uint256 _floating = totalAvailableAsset_ == 0 ? 0 : totalAvailableAsset_ - assetAmt;
    uint256 _ratePerSec = _calculateInterestRate(totalBorrows, _floating) / SECONDS_PER_YEAR;

    // First division is due to _ratePerSec being in 1e18
    // Second division is due to _ratePerSec being in 1e18
    return _ratePerSec * totalBorrows * _timePassed / SAFE_MULTIPLIER;
  }

  /**
    * @notice Conversion factor for tokens with less than 1e18 to return in 1e18
    * @return conversionFactor  Amount of decimals for conversion to 1e18
  */
  function _to18ConversionFactor() internal view returns (uint256) {
    unchecked {
      if (ERC20(address(asset)).decimals() == 18) return 1;

      return 10**(18 - ERC20(address(asset)).decimals());
    }
  }

  /**
    * @notice Return the interest rate based on the utilization rate
    * @param debt Total borrowed amount
    * @param floating Total available liquidity
    * @return rate Current interest rate in 1e18
  */
  function _calculateInterestRate(uint256 debt, uint256 floating) internal view returns (uint256) {
    if (debt == 0 && floating == 0) return 0;

    uint256 _total = debt + floating;
    uint256 _utilization = debt * SAFE_MULTIPLIER / _total;

    // If _utilization above kink2, return a higher interest rate
    // (base + rate + excess _utilization above kink 2 * jumpMultiplier)
    if (_utilization > interestRate.kink2) {
      return interestRate.baseRate + (interestRate.kink1 * interestRate.multiplier / SAFE_MULTIPLIER)
                      + ((_utilization - interestRate.kink2) * interestRate.jumpMultiplier / SAFE_MULTIPLIER);
    }

    // If _utilization between kink1 and kink2, rates are flat
    if (interestRate.kink1 < _utilization && _utilization <= interestRate.kink2) {
      return interestRate.baseRate + (interestRate.kink1 * interestRate.multiplier / SAFE_MULTIPLIER);
    }

    // If _utilization below kink1, calculate borrow rate for slope up to kink 1
    return interestRate.baseRate + (_utilization * interestRate.multiplier / SAFE_MULTIPLIER);
  }

  /* ================= RESTRICTED FUNCTIONS ================== */

  /**
    * @notice Updates lending vault interest rate model variables, callable only by keeper
    * @param newInterestRate InterestRate struct
  */
  function updateInterestRate(InterestRate memory newInterestRate) public onlyKeeper {
    if (
      newInterestRate.baseRate > maxInterestRate.baseRate ||
      newInterestRate.multiplier > maxInterestRate.multiplier ||
      newInterestRate.jumpMultiplier > maxInterestRate.jumpMultiplier ||
      newInterestRate.kink1 > maxInterestRate.kink1 ||
      newInterestRate.kink2 > maxInterestRate.kink2
    ) revert Errors.InterestRateModelExceeded();

    interestRate.baseRate = newInterestRate.baseRate;
    interestRate.multiplier = newInterestRate.multiplier;
    interestRate.jumpMultiplier = newInterestRate.jumpMultiplier;
    interestRate.kink1 = newInterestRate.kink1;
    interestRate.kink2 = newInterestRate.kink2;

    emit UpdateInterestRate(
      interestRate.baseRate,
      interestRate.multiplier,
      interestRate.jumpMultiplier,
      interestRate.kink1,
      interestRate.kink2
    );
  }

  /**
    * @notice Update perf fee
    * @param newPerformanceFee  Fee percentage in 1e18
  */
  function updatePerformanceFee(uint256 newPerformanceFee) external onlyOwner {
    // Update vault with accrued interest and latest timestamp
    _updateVaultWithInterestsAndTimestamp(0);

    performanceFee = newPerformanceFee;

    emit PerformanceFeeUpdated(msg.sender, performanceFee, newPerformanceFee);
  }

  /**
    * @notice Approve address to borrow from this vault
    * @param borrower  Borrower address
  */
  function approveBorrower(address borrower) external onlyOwner {
    if (borrowers[borrower].approved) revert Errors.BorrowerAlreadyApproved();

    borrowers[borrower].approved = true;
  }

  /**
    * @notice Revoke address to borrow from this vault
    * @param borrower  Borrower address
  */
  function revokeBorrower(address borrower) external onlyOwner {
    if (!borrowers[borrower].approved) revert Errors.BorrowerAlreadyRevoked();

    borrowers[borrower].approved = false;
  }

  /**
    * @notice Approve or revoke address to be a keeper for this vault
    * @param keeper Keeper address
    * @param approval Boolean to approve keeper or not
  */
  function updateKeeper(address keeper, bool approval) external onlyOwner {
    if (keeper == address(0)) revert Errors.ZeroAddressNotAllowed();

    keepers[keeper] = approval;
  }

  /**
    * @notice Emergency repay of assets to lending vault to clear bad debt
    * @param repayAmt Amount of debt to repay in token decimals
  */
  function emergencyRepay(uint256 repayAmt, address defaulter) external nonReentrant onlyKeeper {
    if (repayAmt <= 0) revert Errors.InsufficientRepayAmount();

    // Update vault with accrued interest and latest timestamp
    _updateVaultWithInterestsAndTimestamp(0);

    uint256 maxRepay_ = maxRepay(defaulter);

    if (maxRepay_ > 0) {
      if (repayAmt > maxRepay_) {
        repayAmt = maxRepay_;
      }

      // Calculate debt to reduce based on repay amount
      uint256 _debt = repayAmt * borrowers[defaulter].debt / maxRepay_;

      // Update vault state
      totalBorrows = totalBorrows - repayAmt;
      totalBorrowDebt = totalBorrowDebt - _debt;

      // Update borrower state
      borrowers[defaulter].debt = borrowers[defaulter].debt - _debt;
      borrowers[defaulter].lastUpdatedAt = block.timestamp;

      // Transfer repay tokens to the vault
      asset.safeTransferFrom(msg.sender, address(this), repayAmt);

      emit Repay(defaulter, _debt, repayAmt);
    }
  }

  /**
    * @notice Emergency pause of lending vault that pauses all deposits, borrows and normal withdrawals
  */
  function emergencyShutdown() external whenNotPaused onlyKeeper {
    _pause();

    emit EmergencyShutdown(msg.sender);
  }

  /**
    * @notice Emergency resume of lending vault that pauses all deposits, borrows and normal withdrawals
  */
  function emergencyResume() external whenPaused onlyOwner {
    _unpause();

    emit EmergencyResume(msg.sender);
  }

  /**
    * @notice Update max capacity value
    * @param newMaxCapacity Capacity value in token decimals (amount)
  */
  function updateMaxCapacity(uint256 newMaxCapacity) external onlyOwner {
    maxCapacity = newMaxCapacity;

    emit UpdateMaxCapacity(newMaxCapacity);
  }

  /**
    * @notice Updates maximum allowed lending vault interest rate model variables
    * @param newMaxInterestRate InterestRate struct
  */
  function updateMaxInterestRate(InterestRate memory newMaxInterestRate) public onlyOwner {
    maxInterestRate.baseRate = newMaxInterestRate.baseRate;
    maxInterestRate.multiplier = newMaxInterestRate.multiplier;
    maxInterestRate.jumpMultiplier = newMaxInterestRate.jumpMultiplier;
    maxInterestRate.kink1 = newMaxInterestRate.kink1;
    maxInterestRate.kink2 = newMaxInterestRate.kink2;

    emit UpdateMaxInterestRate(
      maxInterestRate.baseRate,
      maxInterestRate.multiplier,
      maxInterestRate.jumpMultiplier,
      maxInterestRate.kink1,
      maxInterestRate.kink2
    );
  }

  /**
    * @notice Update treasury address
    * @param newTreasury Treasury address
  */
  function updateTreasury(address newTreasury) external onlyOwner {
    if (newTreasury == address(0)) revert Errors.ZeroAddressNotAllowed();

    treasury = newTreasury;
  }

  /* ================== FALLBACK FUNCTIONS =================== */

  /**
    * @notice Fallback function to receive native token sent to this contract,
    * needed for receiving native token to contract when unwrapped
  */
  receive() external payable {
    if (!isNativeAsset) revert Errors.OnlyNonNativeDepositToken();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library Errors {

  /* ===================== AUTHORIZATION ===================== */

  error OnlyKeeperAllowed();
  error OnlyVaultAllowed();
  error OnlyBorrowerAllowed();

  /* ======================== GENERAL ======================== */


  error ZeroAddressNotAllowed();
  error TokenDecimalsMustBeLessThan18();

  /* ========================= ORACLE ======================== */

  error NoTokenPriceFeedAvailable();
  error FrozenTokenPriceFeed();
  error BrokenTokenPriceFeed();
  error TokenPriceFeedAlreadySet();
  error TokenPriceFeedMaxDelayMustBeGreaterOrEqualToZero();
  error TokenPriceFeedMaxDeviationMustBeGreaterOrEqualToZero();
  error InvalidTokenInLPPool();
  error InvalidReservesInLPPool();
  error OrderAmountOutMustBeGreaterThanZero();
  error SequencerDown();
  error GracePeriodNotOver();

  /* ======================== LENDING ======================== */

  error InsufficientBorrowAmount();
  error InsufficientRepayAmount();
  error BorrowerAlreadyApproved();
  error BorrowerAlreadyRevoked();
  error InsufficientLendingLiquidity();
  error InsufficientAssetsBalance();
  error InterestRateModelExceeded();

  /* ===================== VAULT GENERAL ===================== */

  error InvalidExecutionFeeAmount();
  error InsufficientExecutionFeeAmount();
  error InsufficientSlippageAmount();
  error NotAllowedInCurrentVaultStatus();

  /* ===================== VAULT DEPOSIT ===================== */

  error EmptyDepositAmount();
  error InvalidDepositToken();
  error InsufficientDepositAmount();
  error InvalidNativeDepositAmountValue();
  error InsufficientSharesMinted();
  error InsufficientCapacity();
  error OnlyNonNativeDepositToken();
  error InvalidNativeTokenAddress();
  error DepositAndExecutionFeeDoesNotMatchMsgValue();
  error DepositCancellationCallback();

  /* ===================== VAULT WITHDRAW ==================== */

  error EmptyWithdrawAmount();
  error InvalidWithdrawToken();
  error InsufficientWithdrawAmount();
  error InsufficientWithdrawBalance();
  error InsufficientAssetsReceived();
  error WithdrawNotAllowedInSameDepositBlock();
  error WithdrawalCancellationCallback();

  /* ==================== VAULT REBALANCE ==================== */

  error InvalidDebtRatio();
  error InvalidDelta();
  error InvalidEquity();
  error InsufficientLPTokensMinted();
  error InsufficientLPTokensBurned();
  error InvalidRebalancePreConditions();

  /* ==================== VAULT CALLBACKS ==================== */

  error InvalidDepositKey();
  error InvalidWithdrawKey();
  error InvalidOrderKey();
  error InvalidCallbackHandler();
  error InvalidRefundeeAddress();
}