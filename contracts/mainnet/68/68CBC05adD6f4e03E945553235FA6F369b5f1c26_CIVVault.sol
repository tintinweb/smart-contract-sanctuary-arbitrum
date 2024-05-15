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
pragma solidity 0.8.20;

/// @title TimeOracle
/// @author Civilization
/// @notice This contract is used to track periods of time based on a given epoch duration
/// @dev The owner of the contract can change the epoch duration
contract TimeOracle {
    address public owner; // Owner of the contract
    uint public startTime; // Start time of the tracking
    uint public epochDuration; // Duration of each period in seconds
    uint public currentPeriod; // Current periods elapsed from the start

    /// @notice Initializes the contract with a given epoch duration
    /// @param _epochDuration Duration of each period in seconds
    constructor(uint _epochDuration) {
        owner = msg.sender; // Set the deployer as the owner
        startTime = block.timestamp; // Initialization at deployment time
        epochDuration = _epochDuration;
    }

    /// @notice Calculates the start time for current period
    /// @return currentPeriodStartTime The start time for the current period
    function getCurrentPeriod()
        external
        view
        returns (uint currentPeriodStartTime)
    {
        require(
            block.timestamp >= startTime,
            "TimeOracle: Query before start time"
        );

        // Calculate how many periods have passed since the start
        uint period = (block.timestamp - startTime) /
            epochDuration;

        // Calculate the start time for the current period
        currentPeriodStartTime = startTime + period * epochDuration;

        return currentPeriodStartTime;
    }

    /// @notice Allows the owner to set a new epoch duration
    /// @param _newEpochDuration The new epoch duration in seconds
    function setEpochDuration(uint _newEpochDuration) external {
        require(
            msg.sender == owner,
            "TimeOracle: Only owner can change epochDuration"
        );

        // Calculate the current period before changing epochDuration
        currentPeriod += (block.timestamp - startTime) / epochDuration;

        // Update startTime to now
        startTime = block.timestamp;

        // Update epochDuration
        epochDuration = _newEpochDuration;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title  Civ Vault
 * @author Ren / Frank
 */

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ICivFund.sol";
import "./CIV-VaultGetter.sol";
import "./CIV-VaultFactory.sol";
import "./dependencies/Ownable.sol";

contract CIVVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for ICivFundRT;

    /// @notice All Fees Base Amount
    uint public constant feeBase = 10_000;
    /// @notice Max entry Fee Amount
    uint public constant maxEntryFee = 1_000;
    /// @notice Max users for shares distribution
    uint public maxUsersToDistribute;
    /// @notice Number of strategies
    uint public strategiesCounter;
    /// @notice vault getter contract
    ICivVaultGetter public vaultGetter;
    /// @notice share factory contract
    CIVFundShareFactory public fundShareFactory;
    /// @notice mapping with info on each strategy
    mapping(uint => StrategyInfo) private _strategyInfo;
    /// @notice structure with epoch info
    mapping(uint => mapping(uint => EpochInfo)) private _epochInfo;
    /// @notice Info of each user that enters the fund
    mapping(uint => mapping(address => UserInfo)) private _userInfo;
    /// @notice Counter for the epochs of each strategy
    mapping(uint => uint) private _epochCounter;
    /// @notice Each Strategies epoch informations per address
    mapping(uint => mapping(address => mapping(uint => UserInfoEpoch)))
        private _userInfoEpoch;
    /// @notice Mapping of depositors on a particular epoch
    mapping(uint => mapping(uint => mapping(uint => address)))
        private _depositors;

    ////////////////// EVENTS //////////////////

    /// @notice Event emitted when user deposit fund to our vault or vault deposit fund to strategy
    event Deposit(
        address indexed user,
        address receiver,
        uint indexed id,
        uint amount
    );
    /// @notice Event emitted when user request withdraw fund from our vault or vault withdraw fund to user
    event Withdraw(address indexed user, uint indexed id, uint amount);
    /// @notice Event emitted when owner sets new fee
    event SetFee(
        uint indexed id,
        uint oldFee,
        uint newFee,
        uint oldDuration,
        uint newDuration
    );
    /// @notice Event emitted when owner sets new entry fee
    event SetEntryFee(uint indexed id, uint oldEntryFee, uint newEntryFee);
    /// @notice Event emitted when owner sets new deposit duration
    event SetEpochDuration(uint indexed id, uint oldDuration, uint newDuration);
    /// @notice Event emitted when owner sets new treasury addresses
    event SetWithdrawAddress(
        uint indexed id,
        address[] oldAddress,
        address[] newAddress
    );
    /// @notice Event emitted when owner sets new invest address
    event SetInvestAddress(
        uint indexed id,
        address oldAddress,
        address newAddress
    );
    /// @notice Event emitted when send fee to our treasury
    event SendFeeWithOwner(
        uint indexed id,
        address treasuryAddress,
        uint feeAmount
    );
    /// @notice Event emitted when owner update new VPS
    event UpdateVPS(uint indexed id, uint lastEpoch, uint VPS, uint netVPS);
    /// @notice Event emitted when owner paused deposit
    event SetPaused(uint indexed id, bool paused);
    /// @notice Event emitted when owner set new Max & Min Deposit Amount
    event SetLimits(
        uint indexed id,
        uint oldMaxAmount,
        uint newMaxAmount,
        uint oldMinAmount,
        uint newMinAmount,
        uint oldMaxUsers,
        uint newMaxUsers
    );
    /// @notice Event emitted when user cancel pending deposit from vault
    event CancelDeposit(address indexed user, uint indexed id, uint amount);
    /// @notice Event emitted when user cancel withdraw request from vault
    event CancelWithdraw(address indexed user, uint indexed id, uint amount);
    /// @notice Event emitted when user claim Asset token for each epoch
    event ClaimWithdrawedToken(
        uint indexed id,
        address user,
        uint epoch,
        uint assetAmount
    );
    event SharesDistributed(
        uint indexed id,
        uint epoch,
        address indexed investor,
        uint dueShares
    );
    /// @notice Event emitted when user claim Asset token
    event WithdrawedToken(
        uint indexed id,
        address indexed user,
        uint assetAmount
    );
    /// @notice Event emitted when owner adds new strategy
    event AddStrategy(
        uint indexed id,
        uint fee,
        uint entryFee,
        uint maxDeposit,
        uint minDeposit,
        bool paused,
        address[] withdrawAddress,
        address assetToken,
        uint feeDuration
    );
    /// @notice Event emitted when strategy is initialized
    event InitializeStrategy(uint indexed id);

    ////////////////// ERROR CODES //////////////////
    /*
    ERR_V.1 = "Strategy does not exist";
    ERR_V.2 = "Deposit paused";
    ERR_V.3 = "Treasury Address Length must be 2";
    ERR_V.4 = "Burn failed";
    ERR_V.5 = "Wait for rebalancing to complete";
    ERR_V.6 = "First Treasury address cannot be null address";
    ERR_V.7 = "Second Treasury address cannot be null address";
    ERR_V.8 = "Minting failed";
    ERR_V.9 = "Strategy already initialized";
    ERR_V.10 = "No epochs exist";
    ERR_V.11 = "Nothing to claim";
    ERR_V.12 = "Insufficient contract balance";
    ERR_V.13 = "Not enough amount to withdraw";
    ERR_V.14 = "Strategy address cannot be null address";
    ERR_V.15 = "No pending Fees to distribute";
    ERR_V.16 = "Distribute all shares for previous epoch";
    ERR_V.17 = "Epoch does not exist";
    ERR_V.18 = "Epoch not yet expired";
    ERR_V.19 = "Vault balance is not enough to pay fees";
    ERR_V.20 = "Amount can't be 0";
    ERR_V.21 = "Insufficient User balance";
    ERR_V.22 = "No more users are allowed";
    ERR_V.23 = "Deposit amount exceeds epoch limit";
    ERR_V.24 = "Epoch expired";
    ERR_V.25 = "Current balance not enough";
    ERR_V.26 = "Not enough total withdrawals";
    ERR_V.27 = "VPS not yet updated";
    ERR_V.28 = "Already started distribution";
    ERR_V.29 = "Not yet distributed";
    ERR_V.30 = "Already distributed";
    ERR_V.31 = "Fee duration not yet passed";
    ERR_V.32 = "Withdraw Token cannot be deposit token";
    ERR_V.33 = "Arrays must have same lenght!";
    ERR_V.34 = "Entry fee too high!";
    */

    ////////////////// MODIFIER //////////////////

    modifier checkStrategyExistence(uint _id) {
        require(strategiesCounter > _id, "ERR_V.1");
        _;
    }

    modifier checkEpochExistence(uint _id) {
        require(_epochCounter[_id] > 0, "ERR_V.10");
        _;
    }

    ////////////////// CONSTRUCTOR //////////////////

    constructor() {
        CivVaultGetter getterContract = new CivVaultGetter(address(this));
        fundShareFactory = new CIVFundShareFactory();
        vaultGetter = ICivVaultGetter(address(getterContract));
    }

    ////////////////// INITIALIZATION //////////////////

    /// @notice Add new strategy to our vault
    /// @dev Only Owner can call this function
    /// @param addStrategyParam Parameters for new strategy
    function addStrategy(
        AddStrategyParam memory addStrategyParam
    ) external virtual nonReentrant onlyOwner {
        require(addStrategyParam._withdrawAddresses.length == 2, "ERR_V.3");
        require(
            addStrategyParam._withdrawAddresses[0] != address(0),
            "ERR_V.6"
        );
        require(
            addStrategyParam._withdrawAddresses[1] != address(0),
            "ERR_V.7"
        );
        /// deploy new CIVFundShare contract
        CIVFundShare fundRepresentToken = fundShareFactory.createCIVFundShare();

        _strategyInfo[strategiesCounter] = StrategyInfo({
            assetToken: addStrategyParam._assetToken,
            fundRepresentToken: ICivFundRT(address(fundRepresentToken)),
            fee: addStrategyParam._fee,
            entryFee: addStrategyParam._entryFee,
            withdrawAddress: addStrategyParam._withdrawAddresses,
            investAddress: addStrategyParam._investAddress,
            initialized: false,
            pendingFees: 0,
            maxDeposit: addStrategyParam._maxDeposit,
            maxUsers: addStrategyParam._maxUsers,
            minDeposit: addStrategyParam._minAmount,
            paused: addStrategyParam._paused,
            epochDuration: addStrategyParam._epochDuration,
            feeDuration: addStrategyParam._feeDuration,
            lastFeeDistribution: 0,
            lastProcessedEpoch: 0,
            watermark: 0
        });

        uint id = strategiesCounter;
        strategiesCounter++;

        emit AddStrategy(
            id,
            addStrategyParam._fee,
            addStrategyParam._entryFee,
            addStrategyParam._maxDeposit,
            addStrategyParam._minAmount,
            addStrategyParam._paused,
            addStrategyParam._withdrawAddresses,
            address(addStrategyParam._assetToken),
            addStrategyParam._feeDuration
        );
    }

    /// @notice Internal strategy initialization
    /// @dev Internal function
    /// @param _id strategy id
    function _initializeStrategy(uint _id) internal {
        _strategyInfo[_id].initialized = true;
        vaultGetter.addTimeOracle(_id, _strategyInfo[_id].epochDuration);

        _epochInfo[_id][_epochCounter[_id]] = EpochInfo({
            totDepositors: 0,
            totDepositedAssets: 0,
            totWithdrawnShares: 0,
            VPS: 0,
            netVPS: 0,
            newShares: 0,
            currentWithdrawAssets: 0,
            epochStartTime: block.timestamp,
            lastDepositorProcessed: 0,
            duration: _strategyInfo[_id].epochDuration
        });

        _epochCounter[_id]++;
    }

    /// @notice Delayed strategy start
    /// @dev Only Owner can call this function
    /// @param _id strategy id
    function initializeStrategy(
        uint _id
    ) external onlyOwner checkStrategyExistence(_id) {
        require(!_strategyInfo[_id].initialized, "ERR_V.9");

        _initializeStrategy(_id);
        emit InitializeStrategy(_id);
    }

    // @notice Delayed strategy start with input state
    /// @dev Only Owner can call this function
    /// @param _id strategy id
    /// @param _lastProcessedEpoch last epoch processed
    /// @param _watermark high net watermark for strategy
    /// @param _investors array of depositors
    /// @param _sharesToMint array of shares to mint
    function initializeStrategyWithState(
        uint _id,
        uint _lastProcessedEpoch,
        uint _watermark,
        address[] memory _investors,
        uint[] memory _sharesToMint
    ) external onlyOwner checkStrategyExistence(_id) {
        StrategyInfo storage strategy = _strategyInfo[_id];
        require(!strategy.initialized, "ERR_V.9");
        require(_investors.length == _sharesToMint.length, "ERR_V.33");

        // calculate total shares to mint
        uint sharesToMint;
        for (uint i = 0; i < _sharesToMint.length; i++) {
            sharesToMint += _sharesToMint[i];
        }

        bool success = strategy.fundRepresentToken.mint(sharesToMint);
        require(success, "ERR_V.8");

        // distribute shares to all depositors
        for (uint i = 0; i < _investors.length; i++) {
            if (_sharesToMint[i] > 0) {
                // Transfer the shares
                strategy.fundRepresentToken.safeTransfer(
                    _investors[i],
                    _sharesToMint[i]
                );
            }
        }

        strategy.watermark = _watermark;
        strategy.lastProcessedEpoch = _lastProcessedEpoch;
        _epochCounter[_id] = _lastProcessedEpoch + 1;

        _initializeStrategy(_id);
        emit InitializeStrategy(_id);
    }

    ////////////////// SETTER //////////////////

    /// @notice Sets new fee and new collecting fee duration
    /// @dev Only Owner can call this function
    /// @param _id Strategy Id
    /// @param _newFee New Fee Percent
    /// @param _newDuration New Collecting Fee Duration
    function setFee(
        uint _id,
        uint _newFee,
        uint _newDuration
    ) external onlyOwner checkStrategyExistence(_id) {
        emit SetFee(
            _id,
            _strategyInfo[_id].fee,
            _newFee,
            _strategyInfo[_id].feeDuration,
            _newDuration
        );
        _strategyInfo[_id].fee = _newFee;
        _strategyInfo[_id].feeDuration = _newDuration;
    }

    /// @notice Sets new entry fee
    /// @dev Only Owner can call this function
    /// @param _id Strategy Id
    /// @param _newEntryFee New Fee Percent
    function setEntryFee(
        uint _id,
        uint _newEntryFee
    ) external onlyOwner checkStrategyExistence(_id) {
        emit SetEntryFee(_id, _strategyInfo[_id].entryFee, _newEntryFee);
        require(_newEntryFee <= maxEntryFee, "ERR_V.34");
        _strategyInfo[_id].entryFee = _newEntryFee;
    }

    /// @notice Sets new deposit fund from vault to strategy duration
    /// @dev Only Owner can call this function
    /// @param _id Strategy Id
    /// @param _newDuration New Duration for Deposit fund from vault to strategy
    function setEpochDuration(
        uint _id,
        uint _newDuration
    ) external onlyOwner checkStrategyExistence(_id) {
        emit SetEpochDuration(
            _id,
            _strategyInfo[_id].epochDuration,
            _newDuration
        );
        vaultGetter.setEpochDuration(_id, _newDuration);
        _strategyInfo[_id].epochDuration = _newDuration;
    }

    /// @notice Sets new treasury addresses to keep fee
    /// @dev Only Owner can call this function
    /// @param _id Strategy Id
    /// @param _newAddress Address list to keep fee
    function setWithdrawAddress(
        uint _id,
        address[] memory _newAddress
    ) external onlyOwner checkStrategyExistence(_id) {
        require(_newAddress.length == 2, "ERR_V.3");
        require(_newAddress[0] != address(0), "ERR_V.6");
        require(_newAddress[1] != address(0), "ERR_V.7");
        emit SetWithdrawAddress(
            _id,
            _strategyInfo[_id].withdrawAddress,
            _newAddress
        );
        _strategyInfo[_id].withdrawAddress = _newAddress;
    }

    /// @notice Sets new treasury addresses to keep fee
    /// @dev Only Owner can call this function
    /// @param _id Strategy Id
    /// @param _newAddress Address list to keep fee
    function setInvestAddress(
        uint _id,
        address _newAddress
    ) external onlyOwner checkStrategyExistence(_id) {
        require(_newAddress != address(0), "ERR_V.14");
        emit SetInvestAddress(
            _id,
            _strategyInfo[_id].investAddress,
            _newAddress
        );
        _strategyInfo[_id].investAddress = _newAddress;
    }

    /// @notice Set Pause of Unpause for deposit to vault
    /// @dev Only Owner can change this status
    /// @param _id Strategy Id
    /// @param _paused paused or unpaused for deposit
    function setPaused(
        uint _id,
        bool _paused
    ) external onlyOwner checkStrategyExistence(_id) {
        emit SetPaused(_id, _paused);
        _strategyInfo[_id].paused = _paused;
    }

    /// @notice Set limits on a given strategy
    /// @dev Only Owner can change this status
    /// @param _id Strategy Id
    /// @param _newMaxDeposit New Max Deposit Amount
    /// @param _newMinDeposit New Min Deposit Amount
    /// @param _newMaxUsers New Max User Count
    function setEpochLimits(
        uint _id,
        uint _newMaxDeposit,
        uint _newMinDeposit,
        uint _newMaxUsers
    ) external onlyOwner checkStrategyExistence(_id) {
        emit SetLimits(
            _id,
            _strategyInfo[_id].maxDeposit,
            _newMaxDeposit,
            _strategyInfo[_id].minDeposit,
            _newMinDeposit,
            _strategyInfo[_id].maxUsers,
            _newMaxUsers
        );
        _strategyInfo[_id].maxDeposit = _newMaxDeposit;
        _strategyInfo[_id].minDeposit = _newMinDeposit;
        _strategyInfo[_id].maxUsers = _newMaxUsers;
    }

    /// @notice Set the max number of users per distribution
    /// @param _maxUsersToDistribute Max number of users to distirbute shares to
    function setMaxUsersToDistribute(
        uint _maxUsersToDistribute
    ) external onlyOwner {
        require(
            _maxUsersToDistribute > 0 &&
                _maxUsersToDistribute != maxUsersToDistribute,
            "Invalid number of users"
        );
        maxUsersToDistribute = _maxUsersToDistribute;
    }

    ////////////////// GETTER //////////////////

    /**
     * @dev Fetches the strategy information for a given strategy _id.
     * @param _id The ID of the strategy to fetch the information for.
     * @return strategy The StrategyInfo struct associated with the provided _id.
     */
    function getStrategyInfo(
        uint _id
    )
        external
        view
        checkStrategyExistence(_id)
        returns (StrategyInfo memory strategy)
    {
        strategy = _strategyInfo[_id];
    }

    /**
     * @dev Fetches the epoch information for a given strategy _id.
     * @param _id The ID of the strategy to fetch the information for.
     * @param _index The index of the epoch to fetch the information for.
     * @return epoch The EpochInfo struct associated with the provided _id and _index.
     */
    function getEpochInfo(
        uint _id,
        uint _index
    )
        external
        view
        checkStrategyExistence(_id)
        checkEpochExistence(_id)
        returns (EpochInfo memory epoch)
    {
        epoch = _epochInfo[_id][_index];
    }

    /**
     * @dev Fetches the current epoch number for a given strategy _id.
     * The current epoch is determined as the last index of the epochInfo mapping for the strategy.
     * @param _id The _id of the strategy to fetch the current epoch for.
     * @return The current epoch number for the given strategy _id.
     */
    function getCurrentEpoch(
        uint _id
    )
        public
        view
        checkStrategyExistence(_id)
        checkEpochExistence(_id)
        returns (uint)
    {
        return _epochCounter[_id] - 1;
    }

    /**
     * @dev Fetches the user information for a given strategy _id.
     * @param _id The _id of the strategy to fetch the information for.
     * @param _user The address of the user to fetch the information for.
     * @return user The UserInfo struct associated with the provided _id and _user.
     */
    function getUserInfo(
        uint _id,
        address _user
    ) external view checkStrategyExistence(_id) returns (UserInfo memory user) {
        user = _userInfo[_id][_user];
    }

    /**
     * @dev Fetches the user information for a given strategy _id.
     * @param _id The _id of the strategy to fetch the information for.
     * @param _epoch The starting index to fetch the information for.
     * @return users An array of addresses of unique depositors.
     */
    function getDepositors(
        uint _id,
        uint _epoch
    )
        external
        view
        checkStrategyExistence(_id)
        returns (address[] memory users)
    {
        uint totalDepositors = _epochInfo[_id][_epoch].totDepositors;
        users = new address[](totalDepositors);

        for (uint i = 0; i < totalDepositors; i++) {
            users[i] = _depositors[_id][_epoch][i];
        }
    }

    /**
     * @dev Fetches the deposit parameters for a given strategy _id.
     * @param _id The _id of the strategy to fetch the information for.
     * @param _user The address of the user to fetch the information for.
     * @param _index The index of the deposit to fetch the information for.
     * @return userEpochStruct The UserInfoEpoch struct associated with the provided _id, _user and _index.
     */
    function getUserInfoEpoch(
        uint _id,
        address _user,
        uint _index
    )
        external
        view
        checkStrategyExistence(_id)
        returns (UserInfoEpoch memory userEpochStruct)
    {
        userEpochStruct = _userInfoEpoch[_id][_user][_index];
    }

    ////////////////// UPDATE //////////////////

    /**
     * @dev Updates the current epoch information for the specified strategy
     * @param _id The Strategy _id
     *
     * This function checks if the current epoch's duration has been met or exceeded.
     * If true, it initializes a new epoch with its starting time as the current block timestamp.
     * If false, no action is taken.
     *
     * Requirements:
     * - The strategy must be initialized.
     * - The current block timestamp must be equal to or greater than the start
     *   time of the current epoch plus the epoch's duration.
     */
    function updateEpoch(uint _id) private checkEpochExistence(_id) {
        uint currentEpoch = getCurrentEpoch(_id);

        if (
            block.timestamp >=
            _epochInfo[_id][currentEpoch].epochStartTime +
                _epochInfo[_id][currentEpoch].duration
        ) {
            require(_epochInfo[_id][currentEpoch].VPS > 0, "ERR_V.5");

            _epochInfo[_id][_epochCounter[_id]] = EpochInfo({
                totDepositors: 0,
                totDepositedAssets: 0,
                totWithdrawnShares: 0,
                VPS: 0,
                netVPS: 0,
                newShares: 0,
                currentWithdrawAssets: 0,
                epochStartTime: vaultGetter.getCurrentPeriod(_id),
                lastDepositorProcessed: 0,
                duration: _strategyInfo[_id].epochDuration
            });

            _epochCounter[_id]++;
        }
    }

    /// @notice Calculate fees to the treasury address and save it in the strategy mapping and returns net VPS
    /**
     * @dev Internal function
     */
    /// @param _id Strategy _id
    /// @param _newVPS new Net Asset Value
    /// @return netVPS The new VPS after fees have been deducted
    function takePerformanceFees(
        uint _id,
        uint _newVPS
    ) private returns (uint netVPS, uint actualFee) {
        StrategyInfo storage strategy = _strategyInfo[_id];

        uint sharesMultiplier = 10 ** strategy.fundRepresentToken.decimals();
        uint totalSupplyShares = strategy.fundRepresentToken.totalSupply();
        actualFee = 0;
        netVPS = _newVPS;

        if (strategy.watermark < _newVPS) {
            actualFee =
                ((_newVPS - strategy.watermark) *
                    strategy.fee *
                    totalSupplyShares) /
                feeBase /
                sharesMultiplier;
            if (actualFee > 0) {
                strategy.pendingFees += actualFee;
                // Calculate net VPS based on the actual fee
                uint adjustedTotalValue = (_newVPS * totalSupplyShares) /
                    sharesMultiplier -
                    actualFee;
                netVPS =
                    (adjustedTotalValue * sharesMultiplier) /
                    totalSupplyShares;
                strategy.watermark = netVPS;
            }
        }
    }

    /**
     * @dev Processes the fund associated with a particular strategy, handling deposits,
     * minting, and burning of shares.
     * @param _id The Strategy _id
     * @param _newVPS New value per share (VPS) expressed in decimals (same as assetToken)
     * - must be greater than 0
     *
     * This function performs the following actions:
     * 1. Retrieves the current epoch and strategy info, as well as net VPS and performance Fees;
     * 2. Calculate the new shares and current withdrawal based on new VPS;
     * 3. Mints or burns shares depending on the new shares and total withdrawals.
     * 4. Handles deposits, withdrawals and performance fees by transferring the Asset tokens.
     *
     * Requirements:
     * - `_newVPS` must be greater than 0.
     * - The necessary amount of Asset tokens must be present in the contract for deposits if required.
     * - The necessary amount of Asset tokens must be present in the investAddress for withdrawals if required.
     */
    function processFund(uint _id, uint _newVPS) private {
        require(_newVPS > 0, "ERR_V.15");

        uint performanceFees;
        uint netVPS;
        (netVPS, performanceFees) = takePerformanceFees(_id, _newVPS);

        // Step 1
        EpochInfo storage epoch = _epochInfo[_id][
            _strategyInfo[_id].lastProcessedEpoch
        ];
        StrategyInfo memory strategy = _strategyInfo[_id];

        epoch.netVPS = netVPS;
        uint sharesMultiplier = 10 ** strategy.fundRepresentToken.decimals();

        // Reduce totDepositedAssets by entry fee and send fees to withdraw addresses
        uint feeAmount = (epoch.totDepositedAssets * strategy.entryFee) /
            feeBase; // Calculate the fee
        epoch.totDepositedAssets -= feeAmount; // Calculate net amount after fee deduction

        strategy.assetToken.safeTransfer(
            strategy.withdrawAddress[0],
            feeAmount / 2
        );
        strategy.assetToken.safeTransfer(
            strategy.withdrawAddress[1],
            feeAmount / 2
        );

        // Step 2
        uint newShares = (epoch.totDepositedAssets * sharesMultiplier) / netVPS;
        uint currentWithdrawAssets = (netVPS * epoch.totWithdrawnShares) /
            sharesMultiplier;

        epoch.newShares = newShares;
        epoch.currentWithdrawAssets = currentWithdrawAssets;

        // Step 3
        if (newShares > epoch.totWithdrawnShares) {
            uint sharesToMint = newShares - epoch.totWithdrawnShares;
            bool success = strategy.fundRepresentToken.mint(sharesToMint);
            require(success, "ERR_V.8");
        } else {
            uint offSetShares = epoch.totWithdrawnShares - newShares;
            if (offSetShares > 0) {
                bool success = strategy.fundRepresentToken.burn(offSetShares);
                require(success, "ERR_V.4");
            }
        }

        // Step 4
        if (
            epoch.totDepositedAssets >= currentWithdrawAssets + performanceFees
        ) {
            uint netDeposits = epoch.totDepositedAssets -
                currentWithdrawAssets -
                performanceFees;
            if (netDeposits > 0) {
                require(
                    strategy.assetToken.balanceOf(address(this)) >= netDeposits,
                    "ERR_V.12"
                );
                strategy.assetToken.safeTransfer(
                    strategy.investAddress,
                    netDeposits
                );
                emit Deposit(
                    address(this),
                    strategy.investAddress,
                    _id,
                    netDeposits
                );
            }
        } else {
            uint offSet = currentWithdrawAssets +
                performanceFees -
                epoch.totDepositedAssets;
            require(
                strategy.assetToken.balanceOf(strategy.investAddress) >= offSet,
                "ERR_V.13"
            );
            strategy.assetToken.safeTransferFrom(
                strategy.investAddress,
                address(this),
                offSet
            );
        }

        updateEpoch(_id);
        emit UpdateVPS(_id, strategy.lastProcessedEpoch, _newVPS, netVPS);
    }

    /// @notice Sets new VPS of the strategy.
    /**
     * @dev Only Owner can call this function.
     *      Owner must transfer fund to our vault before calling this function
     */
    /// @param _id Strategy _id
    /// @param _newVPS New VPS value
    function rebalancing(
        uint _id,
        uint _newVPS
    ) external nonReentrant onlyOwner checkStrategyExistence(_id) {
        StrategyInfo storage strategy = _strategyInfo[_id];
        require(strategy.investAddress != address(0), "ERR_V.14");

        if (strategy.lastProcessedEpoch == 0) {
            EpochInfo storage initEpoch = _epochInfo[_id][0];
            if (initEpoch.VPS > 0) {
                require(
                    initEpoch.lastDepositorProcessed == initEpoch.totDepositors,
                    "ERR_V.16"
                );
                require(_epochCounter[_id] > 1, "ERR_V.17");
                strategy.lastProcessedEpoch++;
                EpochInfo storage newEpoch = _epochInfo[_id][1];
                require(
                    block.timestamp >=
                        newEpoch.epochStartTime + newEpoch.duration,
                    "ERR_V.18"
                );
                newEpoch.VPS = _newVPS;
            } else {
                require(
                    block.timestamp >=
                        initEpoch.epochStartTime + initEpoch.duration,
                    "ERR_V.18"
                );
                strategy.watermark = _newVPS;
                initEpoch.VPS = _newVPS;
            }
        } else {
            require(
                _epochInfo[_id][strategy.lastProcessedEpoch]
                    .lastDepositorProcessed ==
                    _epochInfo[_id][strategy.lastProcessedEpoch].totDepositors,
                "ERR_V.16"
            );
            strategy.lastProcessedEpoch++;
            require(
                _epochCounter[_id] > strategy.lastProcessedEpoch,
                "ERR_V.17"
            );
            EpochInfo storage subsequentEpoch = _epochInfo[_id][
                strategy.lastProcessedEpoch
            ];
            require(
                block.timestamp >=
                    subsequentEpoch.epochStartTime + subsequentEpoch.duration,
                "ERR_V.18"
            );
            subsequentEpoch.VPS = _newVPS;
        }

        processFund(_id, _newVPS);
    }

    ////////////////// MAIN //////////////////

    /// @notice Users Deposit tokens to our vault
    /**
     * @dev Anyone can call this function if strategy is not paused.
     *      Users must approve deposit token before calling this function
     *      We mint represent token to users so that we can calculate each users deposit amount outside
     */
    /// @param _id Strategy _id
    /// @param _amount Token Amount to deposit
    function deposit(
        uint _id,
        uint _amount
    ) external nonReentrant checkStrategyExistence(_id) {
        require(_strategyInfo[_id].paused == false, "ERR_V.2");
        StrategyInfo storage strategy = _strategyInfo[_id];
        require(_amount > strategy.minDeposit, "ERR_V.20");
        require(
            strategy.assetToken.balanceOf(_msgSender()) >= _amount,
            "ERR_V.21"
        );
        uint curEpoch = getCurrentEpoch(_id);
        EpochInfo storage epoch = _epochInfo[_id][curEpoch];
        require(
            block.timestamp <= epoch.epochStartTime + epoch.duration,
            "ERR_V.5"
        );
        UserInfoEpoch storage userEpoch = _userInfoEpoch[_id][_msgSender()][
            curEpoch
        ];

        require(
            epoch.totDepositedAssets + _amount <= strategy.maxDeposit,
            "ERR_V.23"
        );

        if (!userEpoch.hasDeposited) {
            require(epoch.totDepositors + 1 <= strategy.maxUsers, "ERR_V.22");
            _depositors[_id][curEpoch][epoch.totDepositors] = _msgSender();
            userEpoch.depositIndex = epoch.totDepositors;
            epoch.totDepositors++;
            userEpoch.hasDeposited = true;
        }

        epoch.totDepositedAssets += _amount;
        strategy.assetToken.safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );
        userEpoch.depositInfo += _amount;
        emit Deposit(_msgSender(), address(this), _id, _amount);
    }

    /// @notice Immediately withdraw current pending deposit amount
    /// @param _id Strategy _id
    function cancelDeposit(
        uint _id
    )
        external
        nonReentrant
        checkStrategyExistence(_id)
        checkEpochExistence(_id)
    {
        StrategyInfo storage strategy = _strategyInfo[_id];
        uint curEpoch = getCurrentEpoch(_id);
        EpochInfo storage epoch = _epochInfo[_id][curEpoch];
        require(
            block.timestamp < epoch.epochStartTime + epoch.duration,
            "ERR_V.24"
        );
        UserInfoEpoch storage userEpoch = _userInfoEpoch[_id][_msgSender()][
            curEpoch
        ];
        uint amount = userEpoch.depositInfo;
        require(amount > 0, "ERR_V.20");

        // Reset user's deposit info
        userEpoch.depositInfo = 0;
        epoch.totDepositedAssets -= amount;

        // Transfer the assets back to the user
        strategy.assetToken.safeTransfer(_msgSender(), amount);

        // Handle depositors array update
        if (epoch.totDepositors > 1) {
            // Get the last depositor's address
            address lastDepositor = _depositors[_id][curEpoch][
                epoch.totDepositors - 1
            ];

            // Replace the current user with the last depositor if they are not the last one
            if (userEpoch.depositIndex != epoch.totDepositors - 1) {
                _depositors[_id][curEpoch][
                    userEpoch.depositIndex
                ] = lastDepositor;
                _userInfoEpoch[_id][lastDepositor][curEpoch]
                    .depositIndex = userEpoch.depositIndex;
            }

            // Clear the last depositor's slot
            _depositors[_id][curEpoch][epoch.totDepositors - 1] = address(0);
        } else {
            // Clear the only depositor's slot if there's only one depositor
            _depositors[_id][curEpoch][0] = address(0);
        }

        userEpoch.depositIndex = 0;
        userEpoch.hasDeposited = false;
        epoch.totDepositors--;

        emit CancelDeposit(_msgSender(), _id, amount);
    }

    /// @notice Sends Withdraw Request to vault
    /**
     * @dev Withdraw amount user shares from vault
     */
    /// @param _id Strategy _id
    function withdraw(
        uint _id,
        uint _amount
    )
        external
        nonReentrant
        checkStrategyExistence(_id)
        checkEpochExistence(_id)
    {
        require(_amount > 0, "ERR_V.20");
        uint sharesBalance = _strategyInfo[_id].fundRepresentToken.balanceOf(
            _msgSender()
        );
        require(sharesBalance >= _amount, "ERR_V.25");
        uint curEpoch = getCurrentEpoch(_id);
        require(
            block.timestamp <=
                _epochInfo[_id][curEpoch].epochStartTime +
                    _epochInfo[_id][curEpoch].duration,
            "ERR_V.5"
        );
        UserInfoEpoch storage userEpoch = _userInfoEpoch[_id][_msgSender()][
            curEpoch
        ];
        UserInfo storage user = _userInfo[_id][_msgSender()];
        if (user.lastEpoch > 0 && userEpoch.withdrawInfo == 0)
            _claimWithdrawedTokens(_id, user.lastEpoch, _msgSender());

        _epochInfo[_id][curEpoch].totWithdrawnShares += _amount;
        userEpoch.withdrawInfo += _amount;
        if (user.lastEpoch != curEpoch) user.lastEpoch = curEpoch;
        _strategyInfo[_id].fundRepresentToken.safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );
        emit Withdraw(_msgSender(), _id, _amount);
    }

    /// @notice Immediately withdraw current pending shares amount
    /// @param _id Strategy _id
    function cancelWithdraw(
        uint _id
    )
        external
        nonReentrant
        checkStrategyExistence(_id)
        checkEpochExistence(_id)
    {
        StrategyInfo storage strategy = _strategyInfo[_id];
        uint curEpoch = getCurrentEpoch(_id);
        EpochInfo storage epoch = _epochInfo[_id][curEpoch];
        require(
            block.timestamp < epoch.epochStartTime + epoch.duration,
            "ERR_V.24"
        );
        UserInfoEpoch storage userEpoch = _userInfoEpoch[_id][_msgSender()][
            curEpoch
        ];
        UserInfo storage user = _userInfo[_id][_msgSender()];
        uint amount = userEpoch.withdrawInfo;
        require(amount > 0, "ERR_V.20");
        userEpoch.withdrawInfo = 0;
        user.lastEpoch = 0;
        require(epoch.totWithdrawnShares >= amount, "ERR_V.26");
        epoch.totWithdrawnShares -= amount;
        strategy.fundRepresentToken.safeTransfer(_msgSender(), amount);

        emit CancelWithdraw(_msgSender(), _id, amount);
    }

    /// @notice Internal get withdraw tokens from vault for user
    /**
     * @dev Withdraw user funds from vault
     */
    /// @param _id Strategy _id
    /// @param _user Strategy _id
    function _claimWithdrawedTokens(
        uint _id,
        uint _lastEpoch,
        address _user
    ) internal {
        EpochInfo storage epoch = _epochInfo[_id][_lastEpoch];
        require(epoch.VPS > 0, "ERR_V.27");

        uint withdrawInfo = _userInfoEpoch[_id][_user][_lastEpoch].withdrawInfo;
        uint availableToClaim;
        if (withdrawInfo > 0) {
            uint dueWithdraw = (withdrawInfo * epoch.currentWithdrawAssets) /
                epoch.totWithdrawnShares;

            availableToClaim += dueWithdraw;
            emit ClaimWithdrawedToken(_id, _user, _lastEpoch, dueWithdraw);
        }
        if (availableToClaim > 0)
            _strategyInfo[_id].assetToken.safeTransfer(_user, availableToClaim);
        emit WithdrawedToken(_id, _user, availableToClaim);
    }

    /// @notice Get withdraw tokens from vault
    /**
     * @dev Withdraw my fund from vault
     */
    /// @param _id Strategy _id
    function claimWithdrawedTokens(
        uint _id
    ) external nonReentrant checkStrategyExistence(_id) {
        UserInfo storage user = _userInfo[_id][_msgSender()];
        require(user.lastEpoch > 0, "ERR_V.11");
        _claimWithdrawedTokens(_id, user.lastEpoch, _msgSender());
        user.lastEpoch = 0;
    }

    /// @notice Distribute shares to the epoch depositors
    /// @dev Only Owner can call this function if deposit duration is passed.
    /// @param _id Strategy _id
    function processDeposits(
        uint _id
    ) external nonReentrant onlyOwner checkStrategyExistence(_id) {
        StrategyInfo memory strategy = _strategyInfo[_id];
        EpochInfo memory epoch = _epochInfo[_id][strategy.lastProcessedEpoch];
        require(epoch.VPS > 0, "ERR_V.27");
        require(epoch.lastDepositorProcessed == 0, "ERR_V.28");
        if (epoch.totDepositedAssets == 0) {
            return;
        }

        _distributeShares(_id);
    }

    /**
     * @dev Continues the process of distributing shares for a specific strategy, if possible.
     * This function is only callable by the contract owner.
     * @param _id The _id of the strategy for which to continue distributing shares.
     */
    function continueDistributingShares(
        uint _id
    ) external nonReentrant onlyOwner checkStrategyExistence(_id) {
        // Check if there's anything to distribute
        EpochInfo memory epoch = _epochInfo[_id][
            _strategyInfo[_id].lastProcessedEpoch
        ];
        require(epoch.VPS > 0, "ERR_V.27");
        require(epoch.lastDepositorProcessed != 0, "ERR_V.29");
        require(epoch.lastDepositorProcessed < epoch.totDepositors, "ERR_V.30");
        _distributeShares(_id);
    }

    /**
     * @dev Distributes the newly minted shares among the depositors of a specific strategy.
     * The function processes depositors until maxUsersToDistribute is rechead if it is greater than 0.
     * @param _id The _id of the strategy for which to distribute shares.
     */
    function _distributeShares(uint _id) internal {
        uint lastProcessedEpoch = _strategyInfo[_id].lastProcessedEpoch;
        EpochInfo storage epoch = _epochInfo[_id][lastProcessedEpoch];
        uint sharesToDistribute = epoch.newShares;

        // Calculate loop limit
        uint loopLimit = maxUsersToDistribute > 0
            ? maxUsersToDistribute + epoch.lastDepositorProcessed
            : epoch.totDepositors;

        if (loopLimit > epoch.totDepositors) {
            loopLimit = epoch.totDepositors;
        }

        // Initialize a local counter for last processed index
        uint lastProcessedIndex = epoch.lastDepositorProcessed;

        // Process depositors and distribute shares proportionally
        for (uint i = lastProcessedIndex; i < loopLimit; i++) {
            address investor = _depositors[_id][lastProcessedEpoch][i];
            uint depositInfo = _userInfoEpoch[_id][investor][lastProcessedEpoch]
                .depositInfo;
            uint dueShares = (sharesToDistribute * depositInfo) /
                epoch.totDepositedAssets;

            // Transfer shares if dueShares is greater than 0
            if (dueShares > 0) {
                _strategyInfo[_id].fundRepresentToken.safeTransfer(
                    investor,
                    dueShares
                );
                emit SharesDistributed(
                    _id,
                    lastProcessedEpoch,
                    investor,
                    dueShares
                );
            }

            // Update the local counter
            lastProcessedIndex = i + 1;
        }

        // Update the epoch's last depositor processed after the loop
        epoch.lastDepositorProcessed = lastProcessedIndex;
    }

    /**
     * @notice Distribute pending fees to the treasury addresses
     * @dev Internal function
     */
    /// @param _id Strategy _id
    function sendPendingFees(
        uint _id
    ) external nonReentrant onlyOwner checkStrategyExistence(_id) {
        StrategyInfo storage strategy = _strategyInfo[_id];

        require(
            block.timestamp >=
                strategy.lastFeeDistribution + strategy.feeDuration,
            "ERR_V.31"
        );
        strategy.lastFeeDistribution = block.timestamp;

        uint pendingFees = strategy.pendingFees;
        require(pendingFees > 0, "ERR_V.15");
        require(
            strategy.assetToken.balanceOf(address(this)) >= pendingFees,
            "ERR_V.19"
        );
        strategy.pendingFees = 0;

        address addr0 = strategy.withdrawAddress[0];
        address addr1 = strategy.withdrawAddress[1];
        emit SendFeeWithOwner(_id, addr0, pendingFees / 2);
        emit SendFeeWithOwner(_id, addr1, pendingFees / 2);
        strategy.assetToken.safeTransfer(addr0, pendingFees / 2);
        strategy.assetToken.safeTransfer(addr1, pendingFees / 2);
    }

    /// @notice Withdraw ERC-20 Token to the owner
    /**
     * @dev Only Owner can call this function
     */
    /// @param _tokenContract ERC-20 Token address
    function withdrawERC20(IERC20 _tokenContract) external onlyOwner {
        for (uint i = 0; i < strategiesCounter; i++) {
            require(_strategyInfo[i].assetToken != _tokenContract, "ERR_V.32");
        }
        _tokenContract.safeTransfer(
            _msgSender(),
            _tokenContract.balanceOf(address(this))
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./dependencies/Ownable.sol";

/// @custom:security-contact [email protected]
contract CIVFundShare is ERC20, Ownable {
    constructor(address _owner) ERC20("CIVFundShare", "FUNDSHARE") {
        _transferOwnership(_owner);
    }

    function mint(uint _amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), _amount);
        return true;
    }

    function burn(uint _amount) public returns (bool) {
        _burn(_msgSender(), _amount);
        return true;
    }
}

contract CIVFundShareFactory {
    function createCIVFundShare() public returns (CIVFundShare) {
        CIVFundShare fundRepresentToken = new CIVFundShare(msg.sender);
        return fundRepresentToken;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./interfaces/ICivFund.sol";
import "./CIV-TimeOracle.sol";

////////////////// ERROR CODES //////////////////
/*
    ERR_VG.1 = "Msg.sender is not the Vault";
    ERR_VG.2 = "Nothing to withdraw";
    ERR_VG.3 = "Wait for the previos epoch to settle before requesting withdraw";
*/

contract CivVaultGetter {
    ICivVault public civVault;

    /// @notice Each Strategy time Oracle
    mapping(uint => TimeOracle) public timeOracle;

    modifier onlyVault() {
        require(msg.sender == address(civVault), "ERR_VG.1");
        _;
    }

    constructor(address _civVaultAddress) {
        civVault = ICivVault(_civVaultAddress);
    }

    /// @notice Deploy new Time Oracle for the strategy
    /// @param _id Strategy Id
    /// @param _epochDuration Epoch Duration
    function addTimeOracle(uint _id, uint _epochDuration) external onlyVault {
        timeOracle[_id] = new TimeOracle(_epochDuration);
    }

    /// @notice Set new epochDuration for Strategy
    /// @dev Only the Getter can call this function from timeOracle
    /// @param _id Strategy Id
    /// @param _newEpochDuration new epochDuration
    function setEpochDuration(uint _id, uint _newEpochDuration) public {
        timeOracle[_id].setEpochDuration(_newEpochDuration);
    }

    /**
     * @dev Get the current period for a Strategy
     * @param _id The ID of the Strategy
     * @return currentPeriodStartTime The end time for the current period
     */
    function getCurrentPeriod(
        uint _id
    ) external view returns (uint currentPeriodStartTime) {
        return timeOracle[_id].getCurrentPeriod();
    }

    /**
     * @dev Retrieves the current balance of the user's fund representative token, and liquidity strategy token in a specific strategy.
     * @param _id The ID of the strategy from which to retrieve user balance information.
     * @param _user The user EOA
     * @return representTokenBalance The balance of the user's fund representative token in the given strategy.
     * @return assetTokenBalance The balance of the user's liquidity strategy token in the given strategy.
     * @return representTokenAddress The contract address of the fund representative token in the given strategy.
     * @return assetTokenAddress The contract address of the liquidity strategy token in the given strategy.
     */
    function getUserBalances(
        uint _id,
        address _user
    )
        external
        view
        returns (
            uint representTokenBalance,
            uint assetTokenBalance,
            address representTokenAddress,
            address assetTokenAddress
        )
    {
        representTokenAddress = address(
            civVault.getStrategyInfo(_id).fundRepresentToken
        );
        IERC20 representToken = IERC20(representTokenAddress);
        representTokenBalance = representToken.balanceOf(_user);

        assetTokenAddress = address(civVault.getStrategyInfo(_id).assetToken);
        IERC20 assetToken = IERC20(assetTokenAddress);
        assetTokenBalance = assetToken.balanceOf(_user);

        return (
            representTokenBalance,
            assetTokenBalance,
            representTokenAddress,
            assetTokenAddress
        );
    }

    /// @notice get unclaimed withdrawed token epochs
    /// @param _id Strategy Id
    /// @return _epochs array of unclaimed epochs
    function getUnclaimedTokens(
        uint _id,
        address _user
    ) public view returns (uint) {
        uint lastEpoch = civVault.getUserInfo(_id, _user).lastEpoch;
        require(lastEpoch > 0, "ERR_VG.2");
        EpochInfo memory epoch = civVault.getEpochInfo(_id, lastEpoch);
        require(epoch.VPS > 0, "ERR_VG.3");
        uint withdrawInfo = civVault
            .getUserInfoEpoch(_id, _user, lastEpoch)
            .withdrawInfo;

        return
            (withdrawInfo * epoch.currentWithdrawAssets) /
            epoch.totWithdrawnShares;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)
// Modified

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct StrategyInfo {
    // Info on each strategy
    IERC20 assetToken; // Address of asset token e.g. USDT
    ICivFundRT fundRepresentToken; // Fund Represent tokens for deposit in the strategy XCIV
    uint fee; // Strategy Fee Amount
    uint entryFee; // Strategy Entry Fee Amount
    uint maxDeposit; // Strategy Max Deposit Amount per Epoch
    uint maxUsers; // Strategy Max User per Epoch
    uint minDeposit; // Strategy Min Deposit Amount
    uint epochDuration; // Duration of an Epoch
    uint feeDuration; // Fee withdraw period
    uint lastFeeDistribution; // Last timestamp of distribution
    uint lastProcessedEpoch; // Last Epoch Processed
    uint watermark; // Fee watermark
    uint pendingFees; // Pending fees that owner can withdraw
    address[] withdrawAddress; // Strategy Withdraw Address
    address investAddress; // Strategy Invest Address
    bool initialized; // Is strategy initialized?
    bool paused; // Flag that deposit is paused or not
}

struct EpochInfo {
    uint totDepositors; // Current depositors of the epoch
    uint totDepositedAssets; // Tot deposited asset in current epoch
    uint totWithdrawnShares; // Tot withdrawn asset in current epoch
    uint VPS; // VPS after rebalancing
    uint netVPS; // Net VPS after rebalancing
    uint newShares; // New shares after rebalancing
    uint currentWithdrawAssets; // Withdrawn asset after rebalancing
    uint epochStartTime; // Epoch start time from time oracle
    uint lastDepositorProcessed; // Last depositor that has recived shares
    uint duration;
}

struct UserInfo {
    uint lastEpoch; // Last withdraw epoch
}

struct UserInfoEpoch {
    uint depositInfo;
    uint withdrawInfo;
    uint depositIndex;
    bool hasDeposited;
}

struct AddStrategyParam {
    IERC20 _assetToken;
    uint _maxDeposit;
    uint _maxUsers;
    uint _minAmount;
    uint _fee;
    uint _entryFee;
    uint _epochDuration;
    uint _feeDuration;
    address _investAddress;
    address[] _withdrawAddresses;
    bool _paused;
}

interface ICivVault {
    function feeBase() external view returns (uint);

    function getStrategyInfo(
        uint _id
    ) external view returns (StrategyInfo memory);

    function getEpochInfo(
        uint _id,
        uint _index
    ) external view returns (EpochInfo memory);

    function getCurrentEpoch(uint _id) external view returns (uint);

    function getUserInfo(
        uint _id,
        address _user
    ) external view returns (UserInfo memory);

    function getUserInfoEpoch(
        uint _id,
        address _user,
        uint _index
    ) external view returns (UserInfoEpoch memory);
}

interface ICivFundRT is IERC20 {
    function decimals() external view returns (uint8);
    function mint(uint _amount) external returns (bool);
    function burn(uint _amount) external returns (bool);
}

interface ICivVaultGetter {
    function getBalanceOfUser(uint, address) external view returns (uint);
    function addTimeOracle(uint, uint) external;
    function setEpochDuration(uint, uint) external;
    function getCurrentPeriod(uint) external view returns (uint);
}

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint);
    function symbol() external view returns (string memory);
}