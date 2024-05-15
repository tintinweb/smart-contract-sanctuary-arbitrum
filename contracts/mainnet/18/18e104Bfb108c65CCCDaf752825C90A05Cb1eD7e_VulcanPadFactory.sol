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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
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
pragma solidity ^0.8.19;

/**
 * Submitted for verification at basescan.org on 2024-04-2

                                                       
                              *                              
                      **       ***                             
                      ****     ****                            
           *          *****    ******                           
          ***          ***     ********        *                 
          ***                  **********      ***               
         ******               ***********     *****               
         ******   ****       *************   *****               
          ****   ******    ****************   **                
               ********* *******  *********                     
            *****************      ********     ***             
          *****************        *******  ******             
         *****************      *   **************             
        ************ ****      **    **************             
      ***********     *      ***       *************             
      ***********         ******        **   *******             
      **********        *********           ********             
      ********** **   ***********     *      *******              
       ****** *  *************   ******    ********              
        *****    *********************     *******               
         ******  ********************      ******                
          ******   *****************     ******                  
             ******  *************    *******                    
               ********       *********                       
                     ********                    ⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ 
 _     _           _                            ______               __          
| |   | |         | |                          (_____ \              | |   
| |   | |  _   _  | |  ____   __ _   _ __       _____) )  ____    ___| |  
| |   | | | | | | | | /  _ ) / _  | |  _  \    |  ____/  / _  |  /  _| |  
 \ \_/ /  | |_| | | |( (__  ( ( | | | | | |    | |      ( ( | | (  |_| |  
  \___/    \__,_) |_| \____) \_||_| |_| |_|    |_|       \_||_|  \_____) ⠀⠀
  ⠀

 *  https://vulcan.pad
 **/

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Vulcan is ReentrancyGuard {
    /// @dev struct for token info
    struct TOKEN {
        string name;
        string symbol;
        uint256 totalSupply;
        address tokenAddress;
        uint256 decimal;
        uint256 price;
    }

    /// @dev struct for fee distribution
    struct DISTRIBUTION {
        bool distributed;
        address distributor;
        uint256 timestamp;
    }

    /// @dev struct for fee refund
    struct REFUND {
        bool refunded;
        address refunder;
        uint256 timestamp;
    }

    /// @dev structure for investment details
    struct HISTORY {
        address investor;
        address contributor;
        uint256 amount;
        uint256 timestamp;
    }

    /// @dev enum for representing ICO's state
    enum ICOState {
        PROGRESS,
        FAILED,
        SUCCESS_SOFTCAP,
        SUCCESS_HARDCAP
    }

    /// @dev listing partner's address
    address public lister;

    /// @dev contract owner
    address public owner;

    /// @dev contract owner
    address public daoAddress;

    /// @dev ICO start time
    uint256 public startTime;

    //@dev immutables
    IERC20 public immutable token;

    /// @dev ICO creator
    address public creator;

    /// @dev account that funds will go to after success
    address public fundsAddress;

    /// @dev project metadata URI
    string public projectURI;

    /// @dev ICO hardcap
    uint256 public hardcap;

    /// @dev ICO softcap
    uint256 public softcap;

    /// @dev endTime
    uint256 public endTime;

    /// @dev token info
    TOKEN public tokenInfo;

    /// @dev funds raised from ICO
    uint256 public fundsRaised;

    /// @dev Tracks investors
    address[] public investors;

    /// @dev Tracks contributions of investors
    mapping(address => uint256) public investments;

    // @dev Tracks contribution partners
    address[] public contributors;

    // @dev test if funds are distributed
    DISTRIBUTION public distribution;

    // @dev test if funds are refunded
    REFUND public refund;

    // @dev investment history
    HISTORY[] public history;

    // @dev Tracks contributions of contribution partners
    mapping(address => uint256) public contributions;

    /// @dev validate if token address is non-zero
    modifier notZeroTokenAddress(address address_) {
        require(address_ != address(0), "Invalid TOKEN address");
        _;
    }

    /// @dev validate if token address is non-zero
    modifier notZeroFundsAddress(address address_) {
        require(address_ != address(0), "Invalid account address that funds will go to");
        _;
    }

    /// @dev validate if dao address is non-zero
    modifier notZeroDaoAddress(address daoAddress_) {
        require(daoAddress_ != address(0), "Invalid DAO address");
        _;
    }

    /// @dev validate if listing partner's address is non-zero
    modifier notZeroListerAddress(address lister_) {
        require(lister_ != address(0), "Invalid listing partner's address");
        _;
    }

    /// @dev validate if token address is non-zero
    modifier notZeroCreator(address creator_) {
        require(creator_ != address(0), "Invalid creator address");
        _;
    }

    /// @dev validate endtime is valid
    modifier isFuture(uint256 endTime_) {
        require(endTime_ > block.timestamp, "End time should be in the future");
        _;
    }

    /// @dev validate softcap & hardcap setting
    modifier capSettingValid(uint256 softcap_, uint256 hardcap_) {
        require(softcap_ > 0, "Softcap must be greater than 0");
        require(hardcap_ > 0, "Hardcap must be greater than 0");
        require(hardcap_ > softcap_, "Softcap must less than hardcap");
        _;
    }

    /// @dev validate if token decimal is zero
    modifier notZeroDecimal(uint256 decimal_) {
        require(decimal_ > 0, "Token decimal must greater than 0");
        _;
    }

    /// @dev validate if token totalsupply is zero
    modifier notZeroTotalSupply(uint256 totalSupply_) {
        require(totalSupply_ > 0, "Token totalSupply must greater than 0");
        _;
    }

    /// @dev validate if tokens have been charged fully according to hardcap
    modifier tokensChargedFully() {
        uint _tokensAvailable = tokensAvailable();
        uint _fundsAbleToRaise = (tokenInfo.price * _tokensAvailable) /
            10 ** tokenInfo.decimal;
        require(
            _fundsAbleToRaise >= hardcap,
            "Tokens have to be charged fully for ICO"
        );
        _;
    }

    /// @dev validate if amount to purchase less than ico balance.
    modifier ableToBuy(uint256 amount_) {
        uint256 _tokensAvailable = tokensAvailable();
        uint256 _tokens = ((amount_ + fundsRaised) * 10 ** tokenInfo.decimal) /
            tokenInfo.price;
        require(
            _tokens <= _tokensAvailable,
            "Insufficient purchase token amount"
        );
        _;
    }

    /// @dev validate if funds can reach the hardcap for this token
    modifier totalSupplyAbleToReachHardcap(
        uint price_,
        uint totalSupply_,
        uint decimal_,
        uint hardcap_
    ) {
        require(
            (price_ * totalSupply_) / 10 ** decimal_ >= hardcap_,
            "Have to be able to reach hardcap"
        );
        _;
    }

    /// @dev event for fee distribution after ico success
    event FeeDistributed(
        address ico,
        address distributor,
        uint256 fundsRaised,
        uint256 daoFee,
        uint256 listerFee,
        uint256 creatorFee,
        uint256 timestamp
    );

    /// @dev event for new investment
    event Invest(
        address ico,
        address investor,
        address contributor,
        uint256 amount,
        uint256 timestamp
    );

    /// @dev event for refunding all funds
    event FundsRefunded(address ico, address caller, uint256 timestamp);

    /**
     * @dev constructor for new ICO launch
     * @param projectURI_ project metadata uri "https://ipfs.."
     * @param softcap_ softcap for ICO 100 * 10**18
     * @param hardcap_ hardcap for ICO  200 * 10**18
     * @param endTime_ ICO end time 1762819200000
     * @param name_ token name "vulcan token"
     * @param symbol_ token symbol "$VULCAN"
     * @param creator_ ICO creator address "0x00f.."
     * @param price_ token price for ICO 0.01 * 10**18
     * @param decimal_ token decimal 18
     * @param totalSupply_ token totalSupply 1000000000 * 10**18
     * @param tokenAddress_ token address 0x810fa...
     * @param fundsAddress_ account address that funds will go to 0x810fa...
     * @param daoAddress_ cryptoSI DAODAO address 0x810fa...
     */
    constructor(
        string memory projectURI_,
        uint256 softcap_,
        uint256 hardcap_,
        uint256 endTime_,
        string memory name_,
        string memory symbol_,
        address creator_,
        uint256 price_,
        uint256 decimal_,
        uint256 totalSupply_,
        address tokenAddress_,
        address daoAddress_,
        address fundsAddress_,
        address lister_
    )
        capSettingValid(softcap_, hardcap_)
        isFuture(endTime_)
        notZeroCreator(creator_)
        notZeroDecimal(decimal_)
        notZeroTotalSupply(totalSupply_)
        totalSupplyAbleToReachHardcap(price_, totalSupply_, decimal_, hardcap_)
        notZeroTokenAddress(tokenAddress_)
        notZeroFundsAddress(fundsAddress_)
        notZeroDaoAddress(daoAddress_)
        notZeroListerAddress(lister_)
    {
        owner = msg.sender;
        daoAddress = daoAddress_;
        lister = lister_;

        projectURI = projectURI_;

        tokenInfo.name = name_;
        tokenInfo.totalSupply = totalSupply_;
        tokenInfo.symbol = symbol_;
        tokenInfo.tokenAddress = tokenAddress_;
        tokenInfo.price = price_;
        tokenInfo.decimal = decimal_;

        fundsAddress = fundsAddress_;
        creator = creator_;
        softcap = softcap_;
        hardcap = hardcap_;
        startTime = block.timestamp;
        endTime = endTime_;

        token = IERC20(tokenAddress_);
    }

    /**
     * @dev return remaining token balance for ICO
     * @return amount token balance as uint256
     */
    function maxAmountToPurchase() public view returns (uint256) {
        uint256 _amount = token.balanceOf(address(this));
        return _amount;
    }

    /// @dev test if tokens are charged fully to reach hardcap
    function tokensFullyCharged() public view returns (bool) {
        uint _tokensAvailable = tokensAvailable();
        uint _fundsAbleToRaise = (tokenInfo.price * _tokensAvailable) / 10 ** tokenInfo.decimal;

        if ( _fundsAbleToRaise >= hardcap ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev return remaining token balance for ICO
     * @return amount token balance as uint256
     */
    function tokensAvailable() public view returns (uint256) {
        uint256 _amount = token.balanceOf(address(this));
        return _amount;
    }

    /**
     * @dev return minimum ETH available to purchase tokens
     * @return amount token balance as uint256
     */
    function minEthAvailable() public view returns (uint256) {
        return (tokenInfo.price * 10 ** tokenInfo.decimal) / 10 ** 18;
    }

    /**
     * @dev return token available to purchase using given Eth
     * @return amount token amount as uint256
     */
    function tokensAvailableByEth(uint256 eth_) public view returns (uint256) {
        return eth_ / tokenInfo.price;
    }

    /**
     * @dev Returns the Eth needed to purchase a equivalent amount of tokens.
     * @param amount_ the amount of tokens
     * @return amount eth as uint256
     */
    function ethdByTokens(uint256 amount_) public view returns (uint256) {
        return (tokenInfo.price * amount_) / 10 ** tokenInfo.decimal;
    }
    /**
     * @dev Returns a token that can be purchased with an equivalent amount of ETH.
     * @param amount_ the amount of eth
     * @return amount token amount as uint256
     */
    function tokensByEth(uint256 amount_) public view returns (uint256) {
        return (amount_ * 10 ** tokenInfo.decimal) / tokenInfo.price;
    }

    /**
     * @dev Calculate the amount of tokens to sell to reach the hard cap.
     * @return amount token amount as uint256
     */
    function totalCap() public view returns (uint256) {
        return hardcap / tokenInfo.price;
    }

    /**
     * @dev buy tokens using ETH
     * @param amount_ ETH amount to invest
     * @param contributor_ contribution partner's address
     */
    function invest(
        uint amount_,
        address contributor_
    ) external payable nonReentrant tokensChargedFully ableToBuy(amount_) {

        require(block.timestamp < endTime, "ICO is ended");
        require(amount_ > 0, "Invalid amount");
        require(msg.value >= amount_, "Insufficient Eth amount");
        require(contributor_ != address(0), "Invalid contributor's address");

        if(investments[msg.sender] == 0) investors.push(msg.sender) ;
        investments[msg.sender] += amount_;

        if (contributions[contributor_] == 0) contributors.push(contributor_);
        contributions[contributor_] += amount_;

        uint256 _gap = msg.value - amount_;
        if (_gap > 0) {
            payable(msg.sender).transfer(_gap); // If there is any ETH left after purchasing tokens, it will be refunded.
        }

        // save investment history
        history.push(HISTORY(
            msg.sender,
            contributor_,
            amount_,
            block.timestamp
        ));

        fundsRaised += amount_;
        if (fundsRaised >= hardcap) {
            // Once the funds raised reach the hard cap, the ICO is completed and the funds are distributed.
            endTime = block.timestamp - 1;
            distribute();
        }
        emit Invest(address(this), msg.sender, contributor_, amount_, block.timestamp);
    }

    /**
     * @dev when time is reach, creator finish ico
     */
    function finish() external payable nonReentrant {
        require(block.timestamp > endTime, "ICO not ended yet.");

        if (fundsRaised >= softcap) {
            distribute(); // If funds raised reach softcap, distribute funds
        } else {
            finishNotSuccess(); // If the funds don't reach softcap, all investments will be refunded to investors
        }
    }

    /**
     * @dev If the ICO fails to reach the soft cap before the end of the self-set time, all funds will be refunded to investors.
     */
    function finishNotSuccess() internal {

        // refunds all funds to investors
        for (uint256 i = 0; i < investors.length; i++) {
            address to = investors[i];
            uint256 _amount = investments[to];
            investments[to] = 0;
            if (_amount > 0) payable(to).transfer(_amount);
        }

        // refunds all tokens to creator
        uint256 _tokens = tokensAvailable();
        SafeERC20.safeTransfer(token, creator, _tokens);

        // set refund information
        refund.refunded = true;
        refund.refunder = msg.sender;
        refund.timestamp = block.timestamp;

        emit FundsRefunded(
            address(this),
            msg.sender,
            block.timestamp
        );
    }

    /**
     * @dev Distribute fees to dao and partners and send funds to creators' wallets, and send tokens to investors.
     */
    function distribute() internal {

        bool success = false;
        // funds raised
        uint256 _funds = fundsRaised;
        // cryptoSI DADAO fee 2.5%
        uint256 _daoFee = _funds * 25 / 1000;
        (success, ) = payable(daoAddress).call{ value: _daoFee }("");
        require(success, "Failed to send DAO fee.");
        //listing partner's fee 1%
        uint256 _listerFee = _funds * 10 / 1000;
        (success, ) = payable(lister).call{ value: _listerFee }("");
        require(success, "Failed to send listing partner's fee.");
        //creator's funds 95%
        uint256 _creatorFee = _funds * 95 / 100;
        (success, ) = payable(fundsAddress).call{ value: _creatorFee }("");
        require(success, "Failed to send creator's funds.");
        
        // distribute investor's contribution fees to contribution partners
        for (uint256 i = 0; i < contributors.length; i++) {
            address _to = contributors[i];
            uint256 _amount = contributions[_to] * 15 / 1000;
            // send 1.5% to contribution partner
            (success, ) = payable(_to).call{ value: _amount }("");
            require(success, "Failed to send contribution partner's fee.");
        }
        // distribute tokens to investors
        for (uint256 i = 0; i < investors.length; i++) {
            address _to = investors[i];
            uint256 _amount = investments[_to];
            uint256 _tokens = (_amount * 10 ** tokenInfo.decimal) /
                tokenInfo.price;
            SafeERC20.safeTransfer(token, _to, _tokens);
        }
        // set distribution information
        distribution.distributed = true;
        distribution.distributor = msg.sender;
        distribution.timestamp = block.timestamp;

        emit FeeDistributed(
            address(this),
            msg.sender,
            _funds,
            _daoFee,
            _listerFee,
            _creatorFee,
            block.timestamp
        );
    }

    /**
     * @dev get current state of this ICO
     */
    function getICOState() public view returns (ICOState _state) {
        if (block.timestamp < endTime) {
            _state = ICOState.PROGRESS;
        } else if (fundsRaised >= hardcap) {
            _state = ICOState.SUCCESS_HARDCAP;
        } else if (fundsRaised < softcap) {
            _state = ICOState.FAILED;
        } else {
            _state = ICOState.SUCCESS_SOFTCAP;
        }
        return _state;
    }

    /**
     * @dev get all investors
     */
    function getInvestors() public view returns (address[] memory) {
        return investors;
    }

    /**
     * @dev Get the investor's investment amount
    */
    function getInvestAmount(address from) public view returns (uint256) {
        return investments[from];
    }

    /**
     * @dev Get all contributors
     */
    function getContributors() public view returns (address[] memory) {
        return contributors;
    }

    /**
     * @dev Get contribution partner's fee
     */
    function getContributorAmount(address from) public view returns (uint256) {
        return contributions[from];
    }

    /**
     * @dev get all investment history
     */
    function getHistory() public view returns (HISTORY[] memory) {
        return history;
    }

    function getTokenAmountForInvestor(
        address from
    ) public view returns (uint256) {
        uint256 _amount = investments[from];
        uint256 _tokens = (_amount * 10 ** tokenInfo.decimal) / tokenInfo.price;
        return _tokens;
    }

    receive() external payable { }
    fallback() external payable { }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 *Submitted for verification at https://arbiscan.io/ on 2024-05-16

 
                              *                              
                      **       ***                             
                      ****     ****                            
           *          *****    ******                           
          ***          ***     ********        *                 
          ***                  **********      ***               
         ******               ***********     *****               
         ******   ****       *************   *****               
          ****   ******    ****************   **                
               ********* *******  *********                     
            *****************      ********     ***             
          *****************        *******  ******             
         *****************      *   **************             
        ************ ****      **    **************             
      ***********     *      ***       *************             
      ***********         ******        **   *******             
      **********        *********           ********             
      ********** **   ***********     *      *******              
       ****** *  *************   ******    ********              
        *****    *********************     *******               
         ******  ********************      ******                
          ******   *****************     ******                  
             ******  *************    *******                    
               ********       *********                       
                     ********                    ⠀⠀⠀⠀⠀⠀⠀
 _     _           _                            ______               __          
| |   | |         | |                          (_____ \              | |   
| |   | |  _   _  | |  ____   __ _   _ __       _____) )  ____    ___| |  
| |   | | | | | | | | /  _ ) / _  | |  _  \    |  ____/  / _  |  /  _| |  
 \ \_/ /  | |_| | | |( (__  ( ( | | | | | |    | |      ( ( | | (  |_| |  
  \___/    \__,_) |_| \____) \_||_| |_| |_|    |_|       \_||_|  \_____)⠀

 *  https://vulcan.pad
 **/

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Vulcan.sol";

contract VulcanPadFactory {
    /// @dev owner of the factory
    address public owner;

    /// @dev cryptoSIDADAO address
    address public daoAddress;

    /// @dev DAI ERC20 token
    IERC20 public immutable daiToken;

    /// @dev spam filter fee amount 100 DAI as decimal is 18
    uint256 public feeAmount = 100 ether;

    /// @dev tracks spam filter fee contributions of investors
    mapping(address => uint256) public feeContributions;

    /// @dev created ICOs
    address[] public vulcans;

    /// @dev launched ICO
    mapping(address => bool) isVulcan;

    /// @dev event when user paid 100DAI spam filter fee
    event PaidSpamFilterFee(address user, uint256 amount);

    /// @dev event when new ICO is created
    event ICOCreated(
        address creator,
        address ico,
        string projectURI,
        uint256 softcap,
        uint256 hardcap,
        uint256 startTime,
        uint256 endTime,
        string name,
        string symbol,
        uint256 price,
        uint256 decimal,
        uint256 totalSupply,
        address tokenAddress,
        address fundsAddress,
        address lister
    );

    /// @dev validate if token address is non-zero
    modifier notZeroTokenAddress(address address_) {
        require(address_ != address(0), "Invalid TOKEN address");
        _;
    }

    /// @dev validate if token address is non-zero
    modifier notZeroFundsAddress(address address_) {
        require(address_ != address(0), "Invalid address that funds go to");
        _;
    }

    /// @dev validate if dao address is non-zero
    modifier notZeroDAOAddress(address daoAddress_) {
        require(daoAddress_ != address(0), "Invalid DAO address");
        _;
    }

    /// @dev validate if paid 100DAI spam filter fee
    modifier spamFilterFeePaid(address user_) {
        require(
            feeContributions[user_] >= feeAmount,
            "Not paid spam filter fee"
        );
        _;
    }

    /// @dev validate endtime is valid
    modifier isFuture(uint256 endTime_) {
        require(endTime_ > block.timestamp, "End time should be in the future");
        _;
    }

    /// @dev validate caller is owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    /// @dev validate softcap & hardcap setting
    modifier capSettingValid(uint256 softcap_, uint256 hardcap_) {
        require(softcap_ > 0, "Softcap must be greater than 0");
        require(hardcap_ > 0, "Hardcap must be greater than 0");
        require(hardcap_ > softcap_, "Softcap must less than hardcap");
        _;
    }

    /// @dev validate if token price is zero
    modifier notZeroPrice(uint256 price_) {
        require(price_ > 0, "Token price must greater than 0");
        _;
    }

    /// @dev validate if funds can reach the hardcap for this token
    modifier totalSupplyAbleToReachHardcap(
        uint price_,
        uint totalSupply_,
        uint decimal_,
        uint hardcap_
    ) {
        require(
            (price_ * totalSupply_) / 10 ** decimal_ >= hardcap_,
            "Have to be able to reach hardcap"
        );
        _;
    }

    /// @dev validate if token decimal is zero
    modifier notZeroDecimal(uint256 decimal_) {
        require(decimal_ > 0, "Token decimal must greater than 0");
        _;
    }

    /// @dev validate if token totalsupply is zero
    modifier notZeroTotalSupply(uint256 totalSupply_) {
        require(totalSupply_ > 0, "Token totalSupply must greater than 0");
        _;
    }

    /**
     * @dev contructor
     * @param daiAddress_ DAI stable coin address for paying spam filter fee...
     * @param daoAddress_ cryptoSI DAODAO address...
     */
    constructor(
        address daiAddress_,
        address daoAddress_
    ) notZeroDAOAddress(daoAddress_) {
        require(daiAddress_ != address(0), "Invalid DAI address");
        daiToken = IERC20(daiAddress_);
        daoAddress = daoAddress_;
        owner = msg.sender;
    }
    /**
     * @dev Pay non-refundable spam filter fee of 100DAI
     */
    function paySpamFilterFee() external {
        uint256 _allowance = daiToken.allowance(msg.sender, address(this));
        require(_allowance >= feeAmount, "Insufficient DAI allowance");

        SafeERC20.safeTransferFrom(
            daiToken,
            msg.sender,
            daoAddress,
            feeAmount
        );
        feeContributions[msg.sender] += feeAmount;

        emit PaidSpamFilterFee(msg.sender, feeAmount);
    }
    /**
     * @dev launch new ICO
     * @param projectURI_ project metadata uri "https://ipfs.."
     * @param softcap_ softcap for ICO 100 * 10**18
     * @param hardcap_ hardcap for ICO  200 * 10**18
     * @param endTime_ ICO end time 1762819200000
     * @param name_ token name "vulcan token"
     * @param symbol_ token symbol "$VULCAN"
     * @param price_ token price for ICO 0.01 * 10**18
     * @param decimal_ token decimal 18
     * @param totalSupply_ token totalSupply 1000000000 * 10**18
     * @param tokenAddress_ token address
     * @param fundsAddress_ account address that funds will go to
     * @param lister_ listing partner's address
     */
    function launchNewICO(
        string memory projectURI_,
        uint256 softcap_,
        uint256 hardcap_,
        uint256 endTime_,
        string memory name_,
        string memory symbol_,
        uint256 price_,
        uint256 decimal_,
        uint256 totalSupply_,
        address tokenAddress_,
        address fundsAddress_,
        address lister_
    )
        public
        spamFilterFeePaid(msg.sender)
        capSettingValid(softcap_, hardcap_)
        isFuture(endTime_)
        notZeroTokenAddress(tokenAddress_)
        notZeroFundsAddress(fundsAddress_)
        notZeroPrice(price_)
        totalSupplyAbleToReachHardcap(price_, totalSupply_, decimal_, hardcap_)
        notZeroDecimal(decimal_)
        notZeroTotalSupply(totalSupply_)
        returns (address)
    {
        Vulcan _newVulcan = new Vulcan(
            projectURI_,
            softcap_,
            hardcap_,
            endTime_,
            name_,
            symbol_,
            msg.sender,
            price_,
            decimal_,
            totalSupply_,
            tokenAddress_,
            daoAddress,
            fundsAddress_,
            lister_
        );

        address _vulcan = address(_newVulcan);
        vulcans.push(_vulcan);
        feeContributions[msg.sender] -= feeAmount;

        emit ICOCreated(
            msg.sender,
            _vulcan,
            projectURI_,
            softcap_,
            hardcap_,
            block.timestamp,
            endTime_,
            name_,
            symbol_,
            price_,
            decimal_,
            totalSupply_,
            tokenAddress_,
            fundsAddress_,
            lister_
        );
        return _vulcan;
    }

    /**
     * @dev set DAO address
     */
    function setDAOAddress(
        address daoAddress_
    ) 
        external 
        notZeroDAOAddress(daoAddress_) 
        onlyOwner
    {
        daoAddress = daoAddress_;
    }

    /**
     * @dev Test whether the user has already paid the spam filter fee of 100DAI
     */
    function paidSpamFilterFee(address user_) external view returns (bool) {
        bool _success = feeContributions[user_] >= feeAmount;
        return _success;
    }

    /**
     * @dev get all ico lists
     */
    function getVulcans() public view returns (address[] memory) {
        return vulcans;
    }

    /**
     * @dev set factory's owner
     */
    function setOwner(address owner_) 
        external
        onlyOwner 
    {
        require(owner_ != address(0), "Owner address is not zero!");
        owner = owner_;
    }
}