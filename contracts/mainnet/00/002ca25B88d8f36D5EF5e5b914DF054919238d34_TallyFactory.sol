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
pragma solidity ^0.8.20;

import { SnarkConstants } from "./SnarkConstants.sol";
import { PoseidonT3 } from "./PoseidonT3.sol";
import { PoseidonT4 } from "./PoseidonT4.sol";
import { PoseidonT5 } from "./PoseidonT5.sol";
import { PoseidonT6 } from "./PoseidonT6.sol";

/// @notice A SHA256 hash function for any number of input elements, and Poseidon hash
/// functions for 2, 3, 4, 5, and 12 input elements.
contract Hasher is SnarkConstants {
  /// @notice Computes the SHA256 hash of an array of uint256 elements.
  /// @param array The array of uint256 elements.
  /// @return result The SHA256 hash of the array.
  function sha256Hash(uint256[] memory array) public pure returns (uint256 result) {
    result = uint256(sha256(abi.encodePacked(array))) % SNARK_SCALAR_FIELD;
  }

  /// @notice Computes the Poseidon hash of two uint256 elements.
  /// @param array An array of two uint256 elements.
  /// @return result The Poseidon hash of the two elements.
  function hash2(uint256[2] memory array) public pure returns (uint256 result) {
    result = PoseidonT3.poseidon(array);
  }

  /// @notice Computes the Poseidon hash of three uint256 elements.
  /// @param array An array of three uint256 elements.
  /// @return result The Poseidon hash of the three elements.
  function hash3(uint256[3] memory array) public pure returns (uint256 result) {
    result = PoseidonT4.poseidon(array);
  }

  /// @notice Computes the Poseidon hash of four uint256 elements.
  /// @param array An array of four uint256 elements.
  /// @return result The Poseidon hash of the four elements.
  function hash4(uint256[4] memory array) public pure returns (uint256 result) {
    result = PoseidonT5.poseidon(array);
  }

  /// @notice Computes the Poseidon hash of five uint256 elements.
  /// @param array An array of five uint256 elements.
  /// @return result The Poseidon hash of the five elements.
  function hash5(uint256[5] memory array) public pure returns (uint256 result) {
    result = PoseidonT6.poseidon(array);
  }

  /// @notice Computes the Poseidon hash of two uint256 elements.
  /// @param left the first element to hash.
  /// @param right the second element to hash.
  /// @return result The Poseidon hash of the two elements.
  function hashLeftRight(uint256 left, uint256 right) public pure returns (uint256 result) {
    uint256[2] memory input;
    input[0] = left;
    input[1] = right;
    result = hash2(input);
  }
}

// SPDX-License-Identifier: MIT
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.20;

/// @title Pairing
/// @notice A library implementing the alt_bn128 elliptic curve operations.
library Pairing {
  uint256 public constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

  struct G1Point {
    uint256 x;
    uint256 y;
  }

  // Encoding of field elements is: X[0] * z + X[1]
  struct G2Point {
    uint256[2] x;
    uint256[2] y;
  }

  /// @notice custom errors
  error PairingAddFailed();
  error PairingMulFailed();
  error PairingOpcodeFailed();

  /// @notice The negation of p, i.e. p.plus(p.negate()) should be zero.
  function negate(G1Point memory p) internal pure returns (G1Point memory) {
    // The prime q in the base field F_q for G1
    if (p.x == 0 && p.y == 0) {
      return G1Point(0, 0);
    } else {
      return G1Point(p.x, PRIME_Q - (p.y % PRIME_Q));
    }
  }

  /// @notice r Returns the sum of two points of G1.
  function plus(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
    uint256[4] memory input;
    input[0] = p1.x;
    input[1] = p1.y;
    input[2] = p2.x;
    input[3] = p2.y;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }

    if (!success) {
      revert PairingAddFailed();
    }
  }

  /// @notice r Return the product of a point on G1 and a scalar, i.e.
  ///         p == p.scalarMul(1) and p.plus(p) == p.scalarMul(2) for all
  ///         points p.
  function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
    uint256[3] memory input;
    input[0] = p.x;
    input[1] = p.y;
    input[2] = s;
    bool success;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }

    if (!success) {
      revert PairingMulFailed();
    }
  }

  /// @return isValid The result of computing the pairing check
  ///         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
  ///        For example,
  ///        pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
  function pairing(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2,
    G1Point memory c1,
    G2Point memory c2,
    G1Point memory d1,
    G2Point memory d2
  ) internal view returns (bool isValid) {
    G1Point[4] memory p1;
    p1[0] = a1;
    p1[1] = b1;
    p1[2] = c1;
    p1[3] = d1;

    G2Point[4] memory p2;
    p2[0] = a2;
    p2[1] = b2;
    p2[2] = c2;
    p2[3] = d2;

    uint256 inputSize = 24;
    uint256[] memory input = new uint256[](inputSize);

    for (uint8 i = 0; i < 4; ) {
      uint8 j = i * 6;
      input[j + 0] = p1[i].x;
      input[j + 1] = p1[i].y;
      input[j + 2] = p2[i].x[0];
      input[j + 3] = p2[i].x[1];
      input[j + 4] = p2[i].y[0];
      input[j + 5] = p2[i].y[1];

      unchecked {
        i++;
      }
    }

    uint256[1] memory out;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }

    if (!success) {
      revert PairingOpcodeFailed();
    }

    isValid = out[0] != 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice A library which provides functions for computing Pedersen hashes.
library PoseidonT3 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(uint256[2] memory input) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice A library which provides functions for computing Pedersen hashes.
library PoseidonT4 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(uint256[3] memory input) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice A library which provides functions for computing Pedersen hashes.
library PoseidonT5 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(uint256[4] memory input) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice A library which provides functions for computing Pedersen hashes.
library PoseidonT6 {
  // solhint-disable-next-line no-empty-blocks
  function poseidon(uint256[5] memory input) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { Pairing } from "./Pairing.sol";

/// @title SnarkCommon
/// @notice a Contract which holds a struct
/// representing a Groth16 verifying key
contract SnarkCommon {
  /// @notice a struct representing a Groth16 verifying key
  struct VerifyingKey {
    Pairing.G1Point alpha1;
    Pairing.G2Point beta2;
    Pairing.G2Point gamma2;
    Pairing.G2Point delta2;
    Pairing.G1Point[] ic;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SnarkConstants
/// @notice This contract contains constants related to the SNARK
/// components of MACI.
contract SnarkConstants {
  /// @notice The scalar field
  uint256 internal constant SNARK_SCALAR_FIELD =
    21888242871839275222246405745257275088548364400416034343698204186575808495617;

  /// @notice The public key here is the first Pedersen base
  /// point from iden3's circomlib implementation of the Pedersen hash.
  /// Since it is generated using a hash-to-curve function, we are
  /// confident that no-one knows the private key associated with this
  /// public key. See:
  /// https://github.com/iden3/circomlib/blob/d5ed1c3ce4ca137a6b3ca48bec4ac12c1b38957a/src/pedersen_printbases.js
  /// Its hash should equal
  /// 6769006970205099520508948723718471724660867171122235270773600567925038008762.
  uint256 internal constant PAD_PUBKEY_X =
    10457101036533406547632367118273992217979173478358440826365724437999023779287;
  uint256 internal constant PAD_PUBKEY_Y =
    19824078218392094440610104313265183977899662750282163392862422243483260492317;

  /// @notice The Keccack256 hash of 'Maci'
  uint256 internal constant NOTHING_UP_MY_SLEEVE =
    8370432830353022751713833565135785980866757267633941821328460903436894336785;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AccQueue } from "../trees/AccQueue.sol";

/// @title IMACI
/// @notice MACI interface
interface IMACI {
  /// @notice Get the depth of the state tree
  /// @return The depth of the state tree
  function stateTreeDepth() external view returns (uint8);

  /// @notice Return the main root of the StateAq contract
  /// @return The Merkle root
  function getStateAqRoot() external view returns (uint256);

  /// @notice Allow Poll contracts to merge the state subroots
  /// @param _numSrQueueOps Number of operations
  /// @param _pollId The ID of the active Poll
  function mergeStateAqSubRoots(uint256 _numSrQueueOps, uint256 _pollId) external;

  /// @notice Allow Poll contracts to merge the state root
  /// @param _pollId The active Poll ID
  /// @return The calculated Merkle root
  function mergeStateAq(uint256 _pollId) external returns (uint256);

  /// @notice Get the number of signups
  /// @return numsignUps The number of signups
  function numSignUps() external view returns (uint256);

  /// @notice Get the state AccQueue
  /// @return The state AccQueue
  function stateAq() external view returns (AccQueue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title IMessageProcessor
/// @notice MessageProcessor interface
interface IMessageProcessor {
  /// @notice Get the result of whether there are unprocessed messages left
  /// @return Whether there are unprocessed messages left
  function processingComplete() external view returns (bool);

  /// @notice Get the commitment to the state and ballot roots
  /// @return The commitment to the state and ballot roots
  function sbCommitment() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { DomainObjs } from "../utilities/DomainObjs.sol";
import { IMACI } from "./IMACI.sol";
import { AccQueue } from "../trees/AccQueue.sol";
import { TopupCredit } from "../TopupCredit.sol";

/// @title IPoll
/// @notice Poll interface
interface IPoll {
  /// @notice The number of messages which have been processed and the number of signups
  /// @return numSignups The number of signups
  /// @return numMsgs The number of messages sent by voters
  function numSignUpsAndMessages() external view returns (uint256 numSignups, uint256 numMsgs);

  /// @notice Allows to publish a Topup message
  /// @param stateIndex The index of user in the state queue
  /// @param amount The amount of credits to topup
  function topup(uint256 stateIndex, uint256 amount) external;

  /// @notice Allows anyone to publish a message (an encrypted command and signature).
  /// This function also enqueues the message.
  /// @param _message The message to publish
  /// @param _encPubKey An epheremal public key which can be combined with the
  /// coordinator's private key to generate an ECDH shared key with which
  /// to encrypt the message.
  function publishMessage(DomainObjs.Message memory _message, DomainObjs.PubKey calldata _encPubKey) external;

  /// @notice The first step of merging the MACI state AccQueue. This allows the
  /// ProcessMessages circuit to access the latest state tree and ballots via
  /// currentSbCommitment.
  /// @param _numSrQueueOps Number of operations
  /// @param _pollId The ID of the active Poll
  function mergeMaciStateAqSubRoots(uint256 _numSrQueueOps, uint256 _pollId) external;

  /// @notice The second step of merging the MACI state AccQueue. This allows the
  /// ProcessMessages circuit to access the latest state tree and ballots via
  /// currentSbCommitment.
  /// @param _pollId The ID of the active Poll
  function mergeMaciStateAq(uint256 _pollId) external;

  /// @notice The first step in merging the message AccQueue so that the
  /// ProcessMessages circuit can access the message root.
  /// @param _numSrQueueOps The number of subroot queue operations to perform
  function mergeMessageAqSubRoots(uint256 _numSrQueueOps) external;

  /// @notice The second step in merging the message AccQueue so that the
  /// ProcessMessages circuit can access the message root.
  function mergeMessageAq() external;

  /// @notice Returns the Poll's deploy time and duration
  /// @return _deployTime The deployment timestamp
  /// @return _duration The duration of the poll
  function getDeployTimeAndDuration() external view returns (uint256 _deployTime, uint256 _duration);

  /// @notice Get the result of whether the MACI contract's stateAq has been merged by this contract
  /// @return Whether the MACI contract's stateAq has been merged by this contract
  function stateAqMerged() external view returns (bool);

  /// @notice Get the depths of the merkle trees
  /// @return intStateTreeDepth The depth of the state tree
  /// @return messageTreeSubDepth The subdepth of the message tree
  /// @return messageTreeDepth The depth of the message tree
  /// @return voteOptionTreeDepth The subdepth of the vote option tree
  function treeDepths()
    external
    view
    returns (uint8 intStateTreeDepth, uint8 messageTreeSubDepth, uint8 messageTreeDepth, uint8 voteOptionTreeDepth);

  /// @notice Get the max values for the poll
  /// @return maxMessages The maximum number of messages
  /// @return maxVoteOptions The maximum number of vote options
  function maxValues() external view returns (uint256 maxMessages, uint256 maxVoteOptions);

  /// @notice Get the external contracts
  /// @return maci The IMACI contract
  /// @return messageAq The AccQueue contract
  /// @return topupCredit The TopupCredit contract
  function extContracts() external view returns (IMACI maci, AccQueue messageAq, TopupCredit topupCredit);

  /// @notice Get the hash of coordinator's public key
  /// @return _coordinatorPubKeyHash the hash of coordinator's public key
  function coordinatorPubKeyHash() external view returns (uint256 _coordinatorPubKeyHash);

  /// @notice Get the commitment to the state leaves and the ballots. This is
  /// hash3(stateRoot, ballotRoot, salt).
  /// Its initial value should be
  /// hash(maciStateRootSnapshot, emptyBallotRoot, 0)
  /// Each successful invocation of processMessages() should use a different
  /// salt to update this value, so that an external observer cannot tell in
  /// the case that none of the messages are valid.
  /// @return The commitment to the state leaves and the ballots
  function currentSbCommitment() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { DomainObjs } from "../utilities/DomainObjs.sol";

/// @title ITallyFactory
/// @notice TallyFactory interface
interface ITallyFactory {
  /// @notice Deploy a new Tally contract and return the address.
  /// @param _verifier Verifier contract
  /// @param _vkRegistry VkRegistry contract
  /// @param _poll Poll contract
  /// @param _messageProcessor MessageProcessor contract
  /// @param _owner Owner of the contract
  /// @param _mode Voting mode
  /// @return The deployed contract
  function deploy(
    address _verifier,
    address _vkRegistry,
    address _poll,
    address _messageProcessor,
    address _owner,
    DomainObjs.Mode _mode
  ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { SnarkCommon } from "../crypto/SnarkCommon.sol";

/// @title IVerifier
/// @notice an interface for a Groth16 verifier contract
interface IVerifier {
  /// @notice Verify a zk-SNARK proof
  /// @param _proof The proof
  /// @param vk The verifying key
  /// @param input The public inputs to the circuit
  /// @return Whether the proof is valid given the verifying key and public
  ///          input. Note that this function only supports one public input.
  ///          Refer to the Semaphore source code for a verifier that supports
  ///          multiple public inputs.
  function verify(
    uint256[8] memory _proof,
    SnarkCommon.VerifyingKey memory vk,
    uint256 input
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { SnarkCommon } from "../crypto/SnarkCommon.sol";
import { DomainObjs } from "../utilities/DomainObjs.sol";

/// @title IVkRegistry
/// @notice VkRegistry interface
interface IVkRegistry {
  /// @notice Get the tally verifying key
  /// @param _stateTreeDepth The state tree depth
  /// @param _intStateTreeDepth The intermediate state tree depth
  /// @param _voteOptionTreeDepth The vote option tree depth
  /// @param _mode QV or Non-QV
  /// @return The verifying key
  function getTallyVk(
    uint256 _stateTreeDepth,
    uint256 _intStateTreeDepth,
    uint256 _voteOptionTreeDepth,
    DomainObjs.Mode _mode
  ) external view returns (SnarkCommon.VerifyingKey memory);

  /// @notice Get the process verifying key
  /// @param _stateTreeDepth The state tree depth
  /// @param _messageTreeDepth The message tree depth
  /// @param _voteOptionTreeDepth The vote option tree depth
  /// @param _messageBatchSize The message batch size
  /// @param _mode QV or Non-QV
  /// @return The verifying key
  function getProcessVk(
    uint256 _stateTreeDepth,
    uint256 _messageTreeDepth,
    uint256 _voteOptionTreeDepth,
    uint256 _messageBatchSize,
    DomainObjs.Mode _mode
  ) external view returns (SnarkCommon.VerifyingKey memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMACI } from "./interfaces/IMACI.sol";
import { Hasher } from "./crypto/Hasher.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IPoll } from "./interfaces/IPoll.sol";
import { IMessageProcessor } from "./interfaces/IMessageProcessor.sol";
import { SnarkCommon } from "./crypto/SnarkCommon.sol";
import { IVerifier } from "./interfaces/IVerifier.sol";
import { IVkRegistry } from "./interfaces/IVkRegistry.sol";
import { CommonUtilities } from "./utilities/CommonUtilities.sol";
import { DomainObjs } from "./utilities/DomainObjs.sol";

/// @title Tally
/// @notice The Tally contract is used during votes tallying
/// and by users to verify the tally results.
contract Tally is Ownable(msg.sender), SnarkCommon, CommonUtilities, Hasher, DomainObjs {
  uint256 internal constant TREE_ARITY = 5;

  /// @notice The commitment to the tally results. Its initial value is 0, but after
  /// the tally of each batch is proven on-chain via a zk-SNARK, it should be
  /// updated to:
  ///
  /// QV:
  /// hash3(
  ///   hashLeftRight(merkle root of current results, salt0)
  ///   hashLeftRight(number of spent voice credits, salt1),
  ///   hashLeftRight(merkle root of the no. of spent voice credits per vote option, salt2)
  /// )
  ///
  /// Non-QV:
  /// hash2(
  ///   hashLeftRight(merkle root of current results, salt0)
  ///   hashLeftRight(number of spent voice credits, salt1),
  /// )
  ///
  /// Where each salt is unique and the merkle roots are of arrays of leaves
  /// TREE_ARITY ** voteOptionTreeDepth long.
  uint256 public tallyCommitment;

  uint256 public tallyBatchNum;

  // The final commitment to the state and ballot roots
  uint256 public sbCommitment;

  IVerifier public immutable verifier;
  IVkRegistry public immutable vkRegistry;
  IPoll public immutable poll;
  IMessageProcessor public immutable messageProcessor;
  Mode public immutable mode;

  /// @notice custom errors
  error ProcessingNotComplete();
  error InvalidTallyVotesProof();
  error AllBallotsTallied();
  error NumSignUpsTooLarge();
  error BatchStartIndexTooLarge();
  error TallyBatchSizeTooLarge();
  error NotSupported();

  /// @notice Create a new Tally contract
  /// @param _verifier The Verifier contract
  /// @param _vkRegistry The VkRegistry contract
  /// @param _poll The Poll contract
  /// @param _mp The MessageProcessor contract
  constructor(address _verifier, address _vkRegistry, address _poll, address _mp, Mode _mode) payable {
    verifier = IVerifier(_verifier);
    vkRegistry = IVkRegistry(_vkRegistry);
    poll = IPoll(_poll);
    messageProcessor = IMessageProcessor(_mp);
    mode = _mode;
  }

  /// @notice Pack the batch start index and number of signups into a 100-bit value.
  /// @param _numSignUps: number of signups
  /// @param _batchStartIndex: the start index of given batch
  /// @param _tallyBatchSize: size of batch
  /// @return result an uint256 representing the 3 inputs packed together
  function genTallyVotesPackedVals(
    uint256 _numSignUps,
    uint256 _batchStartIndex,
    uint256 _tallyBatchSize
  ) public pure returns (uint256 result) {
    if (_numSignUps >= 2 ** 50) revert NumSignUpsTooLarge();
    if (_batchStartIndex >= 2 ** 50) revert BatchStartIndexTooLarge();
    if (_tallyBatchSize >= 2 ** 50) revert TallyBatchSizeTooLarge();

    result = (_batchStartIndex / _tallyBatchSize) + (_numSignUps << uint256(50));
  }

  /// @notice Check if all ballots are tallied
  /// @return tallied whether all ballots are tallied
  function isTallied() public view returns (bool tallied) {
    (uint8 intStateTreeDepth, , , ) = poll.treeDepths();
    (uint256 numSignUps, ) = poll.numSignUpsAndMessages();

    // Require that there are untallied ballots left
    tallied = tallyBatchNum * (TREE_ARITY ** intStateTreeDepth) >= numSignUps;
  }

  /// @notice generate hash of public inputs for tally circuit
  /// @param _numSignUps: number of signups
  /// @param _batchStartIndex: the start index of given batch
  /// @param _tallyBatchSize: size of batch
  /// @param _newTallyCommitment: the new tally commitment to be updated
  /// @return inputHash hash of public inputs
  function genTallyVotesPublicInputHash(
    uint256 _numSignUps,
    uint256 _batchStartIndex,
    uint256 _tallyBatchSize,
    uint256 _newTallyCommitment
  ) public view returns (uint256 inputHash) {
    uint256 packedVals = genTallyVotesPackedVals(_numSignUps, _batchStartIndex, _tallyBatchSize);
    uint256[] memory input = new uint256[](4);
    input[0] = packedVals;
    input[1] = sbCommitment;
    input[2] = tallyCommitment;
    input[3] = _newTallyCommitment;
    inputHash = sha256Hash(input);
  }

  /// @notice Update the state and ballot root commitment
  function updateSbCommitment() public onlyOwner {
    // Require that all messages have been processed
    if (!messageProcessor.processingComplete()) {
      revert ProcessingNotComplete();
    }

    if (sbCommitment == 0) {
      sbCommitment = messageProcessor.sbCommitment();
    }
  }

  /// @notice Verify the result of a tally batch
  /// @param _newTallyCommitment the new tally commitment to be verified
  /// @param _proof the proof generated after tallying this batch
  function tallyVotes(uint256 _newTallyCommitment, uint256[8] calldata _proof) public onlyOwner {
    _votingPeriodOver(poll);
    updateSbCommitment();

    // get the batch size and start index
    (uint8 intStateTreeDepth, , , ) = poll.treeDepths();
    uint256 tallyBatchSize = TREE_ARITY ** intStateTreeDepth;
    uint256 batchStartIndex = tallyBatchNum * tallyBatchSize;

    // save some gas because we won't overflow uint256
    unchecked {
      tallyBatchNum++;
    }

    (uint256 numSignUps, ) = poll.numSignUpsAndMessages();

    // Require that there are untallied ballots left
    if (batchStartIndex >= numSignUps) {
      revert AllBallotsTallied();
    }

    bool isValid = verifyTallyProof(_proof, numSignUps, batchStartIndex, tallyBatchSize, _newTallyCommitment);

    if (!isValid) {
      revert InvalidTallyVotesProof();
    }

    // Update the tally commitment and the tally batch num
    tallyCommitment = _newTallyCommitment;
  }

  /// @notice Verify the tally proof using the verifying key
  /// @param _proof the proof generated after processing all messages
  /// @param _numSignUps number of signups for a given poll
  /// @param _batchStartIndex the number of batches multiplied by the size of the batch
  /// @param _tallyBatchSize batch size for the tally
  /// @param _newTallyCommitment the tally commitment to be verified at a given batch index
  /// @return isValid whether the proof is valid
  function verifyTallyProof(
    uint256[8] calldata _proof,
    uint256 _numSignUps,
    uint256 _batchStartIndex,
    uint256 _tallyBatchSize,
    uint256 _newTallyCommitment
  ) public view returns (bool isValid) {
    (uint8 intStateTreeDepth, , , uint8 voteOptionTreeDepth) = poll.treeDepths();

    (IMACI maci, , ) = poll.extContracts();

    // Get the verifying key
    VerifyingKey memory vk = vkRegistry.getTallyVk(maci.stateTreeDepth(), intStateTreeDepth, voteOptionTreeDepth, mode);

    // Get the public inputs
    uint256 publicInputHash = genTallyVotesPublicInputHash(
      _numSignUps,
      _batchStartIndex,
      _tallyBatchSize,
      _newTallyCommitment
    );

    // Verify the proof
    isValid = verifier.verify(_proof, vk, publicInputHash);
  }

  /// @notice Compute the merkle root from the path elements
  /// and a leaf
  /// @param _depth the depth of the merkle tree
  /// @param _index the index of the leaf
  /// @param _leaf the leaf
  /// @param _pathElements the path elements to reconstruct the merkle root
  /// @return current The merkle root
  function computeMerkleRootFromPath(
    uint8 _depth,
    uint256 _index,
    uint256 _leaf,
    uint256[][] calldata _pathElements
  ) internal pure returns (uint256 current) {
    uint256 pos = _index % TREE_ARITY;
    current = _leaf;
    uint8 k;

    uint256[TREE_ARITY] memory level;

    for (uint8 i = 0; i < _depth; ++i) {
      for (uint8 j = 0; j < TREE_ARITY; ++j) {
        if (j == pos) {
          level[j] = current;
        } else {
          if (j > pos) {
            k = j - 1;
          } else {
            k = j;
          }
          level[j] = _pathElements[i][k];
        }
      }

      _index /= TREE_ARITY;
      pos = _index % TREE_ARITY;
      current = hash5(level);
    }
  }

  /// @notice Verify the number of spent voice credits from the tally.json
  /// @param _totalSpent spent field retrieved in the totalSpentVoiceCredits object
  /// @param _totalSpentSalt the corresponding salt in the totalSpentVoiceCredit object
  /// @param _resultCommitment hashLeftRight(merkle root of the results.tally, results.salt) in tally.json file
  /// @param _perVOSpentVoiceCreditsHash only for QV - hashLeftRight(merkle root of the no spent voice credits, salt)
  /// @return isValid Whether the provided values are valid
  function verifySpentVoiceCredits(
    uint256 _totalSpent,
    uint256 _totalSpentSalt,
    uint256 _resultCommitment,
    uint256 _perVOSpentVoiceCreditsHash
  ) public view returns (bool isValid) {
    uint256[3] memory tally;
    tally[0] = _resultCommitment;
    tally[1] = hashLeftRight(_totalSpent, _totalSpentSalt);
    tally[2] = _perVOSpentVoiceCreditsHash;

    if (mode == Mode.QV) {
      isValid = verifyQvSpentVoiceCredits(_totalSpent, _totalSpentSalt, _resultCommitment, _perVOSpentVoiceCreditsHash);
    } else if (mode == Mode.NON_QV) {
      isValid = verifyNonQvSpentVoiceCredits(_totalSpent, _totalSpentSalt, _resultCommitment);
    }
  }

  /// @notice Verify the number of spent voice credits for QV from the tally.json
  /// @param _totalSpent spent field retrieved in the totalSpentVoiceCredits object
  /// @param _totalSpentSalt the corresponding salt in the totalSpentVoiceCredit object
  /// @param _resultCommitment hashLeftRight(merkle root of the results.tally, results.salt) in tally.json file
  /// @param _perVOSpentVoiceCreditsHash hashLeftRight(merkle root of the no spent voice credits per vote option, salt)
  /// @return isValid Whether the provided values are valid
  function verifyQvSpentVoiceCredits(
    uint256 _totalSpent,
    uint256 _totalSpentSalt,
    uint256 _resultCommitment,
    uint256 _perVOSpentVoiceCreditsHash
  ) internal view returns (bool isValid) {
    uint256[3] memory tally;
    tally[0] = _resultCommitment;
    tally[1] = hashLeftRight(_totalSpent, _totalSpentSalt);
    tally[2] = _perVOSpentVoiceCreditsHash;

    isValid = hash3(tally) == tallyCommitment;
  }

  /// @notice Verify the number of spent voice credits for Non-QV from the tally.json
  /// @param _totalSpent spent field retrieved in the totalSpentVoiceCredits object
  /// @param _totalSpentSalt the corresponding salt in the totalSpentVoiceCredit object
  /// @param _resultCommitment hashLeftRight(merkle root of the results.tally, results.salt) in tally.json file
  /// @return isValid Whether the provided values are valid
  function verifyNonQvSpentVoiceCredits(
    uint256 _totalSpent,
    uint256 _totalSpentSalt,
    uint256 _resultCommitment
  ) internal view returns (bool isValid) {
    uint256[2] memory tally;
    tally[0] = _resultCommitment;
    tally[1] = hashLeftRight(_totalSpent, _totalSpentSalt);

    isValid = hash2(tally) == tallyCommitment;
  }

  /// @notice Verify the number of spent voice credits per vote option from the tally.json
  /// @param _voteOptionIndex the index of the vote option where credits were spent
  /// @param _spent the spent voice credits for a given vote option index
  /// @param _spentProof proof generated for the perVOSpentVoiceCredits
  /// @param _spentSalt the corresponding salt given in the tally perVOSpentVoiceCredits object
  /// @param _voteOptionTreeDepth depth of the vote option tree
  /// @param _spentVoiceCreditsHash hashLeftRight(number of spent voice credits, spent salt)
  /// @param _resultCommitment hashLeftRight(merkle root of the results.tally, results.salt)
  // in the tally.json file
  /// @return isValid Whether the provided proof is valid
  function verifyPerVOSpentVoiceCredits(
    uint256 _voteOptionIndex,
    uint256 _spent,
    uint256[][] calldata _spentProof,
    uint256 _spentSalt,
    uint8 _voteOptionTreeDepth,
    uint256 _spentVoiceCreditsHash,
    uint256 _resultCommitment
  ) public view returns (bool isValid) {
    if (mode != Mode.QV) {
      revert NotSupported();
    }

    uint256 computedRoot = computeMerkleRootFromPath(_voteOptionTreeDepth, _voteOptionIndex, _spent, _spentProof);

    uint256[3] memory tally;
    tally[0] = _resultCommitment;
    tally[1] = _spentVoiceCreditsHash;
    tally[2] = hashLeftRight(computedRoot, _spentSalt);

    isValid = hash3(tally) == tallyCommitment;
  }

  /// @notice Verify the result generated from the tally.json
  /// @param _voteOptionIndex the index of the vote option to verify the correctness of the tally
  /// @param _tallyResult Flattened array of the tally
  /// @param _tallyResultProof Corresponding proof of the tally result
  /// @param _tallyResultSalt the respective salt in the results object in the tally.json
  /// @param _voteOptionTreeDepth depth of the vote option tree
  /// @param _spentVoiceCreditsHash hashLeftRight(number of spent voice credits, spent salt)
  /// @param _perVOSpentVoiceCreditsHash hashLeftRight(merkle root of the no spent voice
  /// credits per vote option, perVOSpentVoiceCredits salt)
  /// @return isValid Whether the provided proof is valid
  function verifyTallyResult(
    uint256 _voteOptionIndex,
    uint256 _tallyResult,
    uint256[][] calldata _tallyResultProof,
    uint256 _tallyResultSalt,
    uint8 _voteOptionTreeDepth,
    uint256 _spentVoiceCreditsHash,
    uint256 _perVOSpentVoiceCreditsHash
  ) public view returns (bool isValid) {
    uint256 computedRoot = computeMerkleRootFromPath(
      _voteOptionTreeDepth,
      _voteOptionIndex,
      _tallyResult,
      _tallyResultProof
    );

    if (mode == Mode.QV) {
      uint256[3] memory tally;
      tally[0] = hashLeftRight(computedRoot, _tallyResultSalt);
      tally[1] = _spentVoiceCreditsHash;
      tally[2] = _perVOSpentVoiceCreditsHash;

      isValid = hash3(tally) == tallyCommitment;
    } else if (mode == Mode.NON_QV) {
      uint256[2] memory tally;
      tally[0] = hashLeftRight(computedRoot, _tallyResultSalt);
      tally[1] = _spentVoiceCreditsHash;

      isValid = hash2(tally) == tallyCommitment;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { Tally } from "./Tally.sol";
import { ITallyFactory } from "./interfaces/ITallyFactory.sol";
import { DomainObjs } from "./utilities/DomainObjs.sol";

/// @title TallyFactory
/// @notice A factory contract which deploys Tally contracts.
contract TallyFactory is ITallyFactory, DomainObjs {
  /// @inheritdoc ITallyFactory
  function deploy(
    address _verifier,
    address _vkRegistry,
    address _poll,
    address _messageProcessor,
    address _owner,
    Mode _mode
  ) public virtual returns (address tallyAddr) {
    // deploy Tally for this Poll
    Tally tally = new Tally(_verifier, _vkRegistry, _poll, _messageProcessor, _mode);
    tally.transferOwnership(_owner);
    tallyAddr = address(tally);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title TopupCredit
/// @notice A contract representing a token used to topup a MACI's voter
/// credits
contract TopupCredit is ERC20, Ownable(msg.sender) {
  uint8 public constant DECIMALS = 1;
  uint256 public constant MAXIMUM_AIRDROP_AMOUNT = 100000 * 10 ** DECIMALS;

  /// @notice custom errors
  error ExceedLimit();

  /// @notice create  a new TopupCredit token
  constructor() payable ERC20("TopupCredit", "TopupCredit") {}

  /// @notice mint tokens to an account
  /// @param account the account to mint tokens to
  /// @param amount the amount of tokens to mint
  function airdropTo(address account, uint256 amount) public onlyOwner {
    if (amount >= MAXIMUM_AIRDROP_AMOUNT) {
      revert ExceedLimit();
    }

    _mint(account, amount);
  }

  /// @notice mint tokens to the contract owner
  /// @param amount the amount of tokens to mint
  function airdrop(uint256 amount) public onlyOwner {
    if (amount >= MAXIMUM_AIRDROP_AMOUNT) {
      revert ExceedLimit();
    }

    _mint(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Hasher } from "../crypto/Hasher.sol";

/// @title AccQueue
/// @notice This contract defines a Merkle tree where each leaf insertion only updates a
/// subtree. To obtain the main tree root, the contract owner must merge the
/// subtrees together. Merging subtrees requires at least 2 operations:
/// mergeSubRoots(), and merge(). To get around the gas limit,
/// the mergeSubRoots() can be performed in multiple transactions.
abstract contract AccQueue is Ownable(msg.sender), Hasher {
  // The maximum tree depth
  uint256 public constant MAX_DEPTH = 32;

  /// @notice A Queue is a 2D array of Merkle roots and indices which represents nodes
  /// in a Merkle tree while it is progressively updated.
  struct Queue {
    /// @notice IMPORTANT: the following declares an array of b elements of type T: T[b]
    /// And the following declares an array of b elements of type T[a]: T[a][b]
    /// As such, the following declares an array of MAX_DEPTH+1 arrays of
    /// uint256[4] arrays, **not the other way round**:
    uint256[4][MAX_DEPTH + 1] levels;
    uint256[MAX_DEPTH + 1] indices;
  }

  // The depth of each subtree
  uint256 internal immutable subDepth;

  // The number of elements per hash operation. Should be either 2 (for
  // binary trees) or 5 (quinary trees). The limit is 5 because that is the
  // maximum supported number of inputs for the EVM implementation of the
  // Poseidon hash function
  uint256 internal immutable hashLength;

  // hashLength ** subDepth
  uint256 internal immutable subTreeCapacity;

  // True hashLength == 2, false if hashLength == 5
  bool internal isBinary;

  // The index of the current subtree. e.g. the first subtree has index 0, the
  // second has 1, and so on
  uint256 internal currentSubtreeIndex;

  // Tracks the current subtree.
  Queue internal leafQueue;

  // Tracks the smallest tree of subroots
  Queue internal subRootQueue;

  // Subtree roots
  mapping(uint256 => uint256) internal subRoots;

  // Merged roots
  uint256[MAX_DEPTH + 1] internal mainRoots;

  // Whether the subtrees have been merged
  bool public subTreesMerged;

  // Whether entire merkle tree has been merged
  bool public treeMerged;

  // The root of the shortest possible tree which fits all current subtree
  // roots
  uint256 internal smallSRTroot;

  // Tracks the next subroot to queue
  uint256 internal nextSubRootIndex;

  // The number of leaves inserted across all subtrees so far
  uint256 public numLeaves;

  /// @notice custom errors
  error SubDepthCannotBeZero();
  error SubdepthTooLarge(uint256 _subDepth, uint256 max);
  error InvalidHashLength();
  error DepthCannotBeZero();
  error SubTreesAlreadyMerged();
  error NothingToMerge();
  error SubTreesNotMerged();
  error DepthTooLarge(uint256 _depth, uint256 max);
  error DepthTooSmall(uint256 _depth, uint256 min);
  error InvalidIndex(uint256 _index);
  error InvalidLevel();

  /// @notice Create a new AccQueue
  /// @param _subDepth The depth of each subtree.
  /// @param _hashLength The number of leaves per node (2 or 5).
  constructor(uint256 _subDepth, uint256 _hashLength) payable {
    /// validation
    if (_subDepth == 0) revert SubDepthCannotBeZero();
    if (_subDepth > MAX_DEPTH) revert SubdepthTooLarge(_subDepth, MAX_DEPTH);
    if (_hashLength != 2 && _hashLength != 5) revert InvalidHashLength();

    isBinary = _hashLength == 2;
    subDepth = _subDepth;
    hashLength = _hashLength;
    subTreeCapacity = _hashLength ** _subDepth;
  }

  /// @notice Hash the contents of the specified level and the specified leaf.
  /// This is a virtual function as the hash function which the overriding
  /// contract uses will be either hashLeftRight or hash5, which require
  /// different input array lengths.
  /// @param _level The level to hash.
  /// @param _leaf The leaf include with the level.
  /// @return _hash The hash of the level and leaf.
  // solhint-disable-next-line no-empty-blocks
  function hashLevel(uint256 _level, uint256 _leaf) internal virtual returns (uint256 _hash) {}

  /// @notice Hash the contents of the specified level and the specified leaf.
  /// This is a virtual function as the hash function which the overriding
  /// contract uses will be either hashLeftRight or hash5, which require
  /// different input array lengths.
  /// @param _level The level to hash.
  /// @param _leaf The leaf include with the level.
  /// @return _hash The hash of the level and leaf.
  // solhint-disable-next-line no-empty-blocks
  function hashLevelLeaf(uint256 _level, uint256 _leaf) public view virtual returns (uint256 _hash) {}

  /// @notice Returns the zero leaf at a specified level.
  /// This is a virtual function as the hash function which the overriding
  /// contract uses will be either hashLeftRight or hash5, which will produce
  /// different zero values (e.g. hashLeftRight(0, 0) vs
  /// hash5([0, 0, 0, 0, 0]). Moreover, the zero value may be a
  /// nothing-up-my-sleeve value.
  /// @param _level The level at which to return the zero leaf.
  /// @return zero The zero leaf at the specified level.
  // solhint-disable-next-line no-empty-blocks
  function getZero(uint256 _level) internal virtual returns (uint256 zero) {}

  /// @notice Add a leaf to the queue for the current subtree.
  /// @param _leaf The leaf to add.
  /// @return leafIndex The index of the leaf in the queue.
  function enqueue(uint256 _leaf) public onlyOwner returns (uint256 leafIndex) {
    leafIndex = numLeaves;
    // Recursively queue the leaf
    _enqueue(_leaf, 0);

    // Update the leaf counter
    numLeaves = leafIndex + 1;

    // Now that a new leaf has been added, mainRoots and smallSRTroot are
    // obsolete
    delete mainRoots;
    delete smallSRTroot;
    subTreesMerged = false;

    // If a subtree is full
    if (numLeaves % subTreeCapacity == 0) {
      // Store the subroot
      subRoots[currentSubtreeIndex] = leafQueue.levels[subDepth][0];

      // Increment the index
      currentSubtreeIndex++;

      // Delete ancillary data
      delete leafQueue.levels[subDepth][0];
      delete leafQueue.indices;
    }
  }

  /// @notice Updates the queue at a given level and hashes any subroots
  /// that need to be hashed.
  /// @param _leaf The leaf to add.
  /// @param _level The level at which to queue the leaf.
  function _enqueue(uint256 _leaf, uint256 _level) internal {
    if (_level > subDepth) {
      revert InvalidLevel();
    }

    while (true) {
      uint256 n = leafQueue.indices[_level];

      if (n != hashLength - 1) {
        // Just store the leaf
        leafQueue.levels[_level][n] = _leaf;

        if (_level != subDepth) {
          // Update the index
          leafQueue.indices[_level]++;
        }

        return;
      }

      // Hash the leaves to next level
      _leaf = hashLevel(_level, _leaf);

      // Reset the index for this level
      delete leafQueue.indices[_level];

      // Queue the hash of the leaves into to the next level
      _level++;
    }
  }

  /// @notice Fill any empty leaves of the current subtree with zeros and store the
  /// resulting subroot.
  function fill() public onlyOwner {
    if (numLeaves % subTreeCapacity == 0) {
      // If the subtree is completely empty, then the subroot is a
      // precalculated zero value
      subRoots[currentSubtreeIndex] = getZero(subDepth);
    } else {
      // Otherwise, fill the rest of the subtree with zeros
      _fill(0);

      // Store the subroot
      subRoots[currentSubtreeIndex] = leafQueue.levels[subDepth][0];

      // Reset the subtree data
      delete leafQueue.levels;

      // Reset the merged roots
      delete mainRoots;
    }

    // Increment the subtree index
    uint256 curr = currentSubtreeIndex + 1;
    currentSubtreeIndex = curr;

    // Update the number of leaves
    numLeaves = curr * subTreeCapacity;

    // Reset the subroot tree root now that it is obsolete
    delete smallSRTroot;

    subTreesMerged = false;
  }

  /// @notice A function that queues zeros to the specified level, hashes,
  /// the level, and enqueues the hash to the next level.
  /// @param _level The level at which to queue zeros.
  // solhint-disable-next-line no-empty-blocks
  function _fill(uint256 _level) internal virtual {}

  /// Insert a subtree. Used for batch enqueues.
  function insertSubTree(uint256 _subRoot) public onlyOwner {
    subRoots[currentSubtreeIndex] = _subRoot;

    // Increment the subtree index
    currentSubtreeIndex++;

    // Update the number of leaves
    numLeaves += subTreeCapacity;

    // Reset the subroot tree root now that it is obsolete
    delete smallSRTroot;

    subTreesMerged = false;
  }

  /// @notice Calculate the lowest possible height of a tree with
  /// all the subroots merged together.
  /// @return depth The lowest possible height of a tree with all the
  function calcMinHeight() public view returns (uint256 depth) {
    depth = 1;
    while (true) {
      if (hashLength ** depth >= currentSubtreeIndex) {
        break;
      }
      depth++;
    }
  }

  /// @notice Merge all subtrees to form the shortest possible tree.
  /// This function can be called either once to merge all subtrees in a
  /// single transaction, or multiple times to do the same in multiple
  /// transactions.
  /// @param _numSrQueueOps The number of times this function will call
  ///                       queueSubRoot(), up to the maximum number of times
  ///                       necessary. If it is set to 0, it will call
  ///                       queueSubRoot() as many times as is necessary. Set
  ///                       this to a low number and call this function
  ///                       multiple times if there are many subroots to
  ///                       merge, or a single transaction could run out of
  ///                       gas.
  function mergeSubRoots(uint256 _numSrQueueOps) public onlyOwner {
    // This function can only be called once unless a new subtree is created
    if (subTreesMerged) revert SubTreesAlreadyMerged();

    // There must be subtrees to merge
    if (numLeaves == 0) revert NothingToMerge();

    // Fill any empty leaves in the current subtree with zeros only if the
    // current subtree is not full
    if (numLeaves % subTreeCapacity != 0) {
      fill();
    }

    // If there is only 1 subtree, use its root
    if (currentSubtreeIndex == 1) {
      smallSRTroot = getSubRoot(0);
      subTreesMerged = true;
      return;
    }

    uint256 depth = calcMinHeight();

    uint256 queueOpsPerformed = 0;
    for (uint256 i = nextSubRootIndex; i < currentSubtreeIndex; i++) {
      if (_numSrQueueOps != 0 && queueOpsPerformed == _numSrQueueOps) {
        // If the limit is not 0, stop if the limit has been reached
        return;
      }

      // Queue the next subroot
      queueSubRoot(getSubRoot(nextSubRootIndex), 0, depth);

      // Increment the next subroot counter
      nextSubRootIndex++;

      // Increment the ops counter
      queueOpsPerformed++;
    }

    // The height of the tree of subroots
    uint256 m = hashLength ** depth;

    // Queue zeroes to fill out the SRT
    if (nextSubRootIndex == currentSubtreeIndex) {
      uint256 z = getZero(subDepth);
      for (uint256 i = currentSubtreeIndex; i < m; i++) {
        queueSubRoot(z, 0, depth);
      }
    }

    // Store the smallest main root
    smallSRTroot = subRootQueue.levels[depth][0];
    subTreesMerged = true;
  }

  /// @notice Queues a subroot into the subroot tree.
  /// @param _leaf The value to queue.
  /// @param _level The level at which to queue _leaf.
  /// @param _maxDepth The depth of the tree.
  function queueSubRoot(uint256 _leaf, uint256 _level, uint256 _maxDepth) internal {
    if (_level > _maxDepth) {
      return;
    }

    uint256 n = subRootQueue.indices[_level];

    if (n != hashLength - 1) {
      // Just store the leaf
      subRootQueue.levels[_level][n] = _leaf;
      subRootQueue.indices[_level]++;
    } else {
      // Hash the elements in this level and queue it in the next level
      uint256 hashed;
      if (isBinary) {
        uint256[2] memory inputs;
        inputs[0] = subRootQueue.levels[_level][0];
        inputs[1] = _leaf;
        hashed = hash2(inputs);
      } else {
        uint256[5] memory inputs;
        for (uint8 i = 0; i < n; i++) {
          inputs[i] = subRootQueue.levels[_level][i];
        }
        inputs[n] = _leaf;
        hashed = hash5(inputs);
      }

      // TODO: change recursion to a while loop
      // Recurse
      delete subRootQueue.indices[_level];
      queueSubRoot(hashed, _level + 1, _maxDepth);
    }
  }

  /// @notice Merge all subtrees to form a main tree with a desired depth.
  /// @param _depth The depth of the main tree. It must fit all the leaves or
  ///               this function will revert.
  /// @return root The root of the main tree.
  function merge(uint256 _depth) public onlyOwner returns (uint256 root) {
    // The tree depth must be more than 0
    if (_depth == 0) revert DepthCannotBeZero();

    // Ensure that the subtrees have been merged
    if (!subTreesMerged) revert SubTreesNotMerged();

    // Check the depth
    if (_depth > MAX_DEPTH) revert DepthTooLarge(_depth, MAX_DEPTH);

    // Calculate the SRT depth
    uint256 srtDepth = subDepth;
    while (true) {
      if (hashLength ** srtDepth >= numLeaves) {
        break;
      }
      srtDepth++;
    }

    if (_depth < srtDepth) revert DepthTooSmall(_depth, srtDepth);

    // If the depth is the same as the SRT depth, just use the SRT root
    if (_depth == srtDepth) {
      mainRoots[_depth] = smallSRTroot;
      treeMerged = true;
      return smallSRTroot;
    } else {
      root = smallSRTroot;

      // Calculate the main root

      for (uint256 i = srtDepth; i < _depth; i++) {
        uint256 z = getZero(i);

        if (isBinary) {
          uint256[2] memory inputs;
          inputs[0] = root;
          inputs[1] = z;
          root = hash2(inputs);
        } else {
          uint256[5] memory inputs;
          inputs[0] = root;
          inputs[1] = z;
          inputs[2] = z;
          inputs[3] = z;
          inputs[4] = z;
          root = hash5(inputs);
        }
      }

      mainRoots[_depth] = root;
      treeMerged = true;
    }
  }

  /// @notice Returns the subroot at the specified index. Reverts if the index refers
  /// to a subtree which has not been filled yet.
  /// @param _index The subroot index.
  /// @return subRoot The subroot at the specified index.
  function getSubRoot(uint256 _index) public view returns (uint256 subRoot) {
    if (currentSubtreeIndex <= _index) revert InvalidIndex(_index);
    subRoot = subRoots[_index];
  }

  /// @notice Returns the subroot tree (SRT) root. Its value must first be computed
  /// using mergeSubRoots.
  /// @return smallSubTreeRoot The SRT root.
  function getSmallSRTroot() public view returns (uint256 smallSubTreeRoot) {
    if (!subTreesMerged) revert SubTreesNotMerged();
    smallSubTreeRoot = smallSRTroot;
  }

  /// @notice Return the merged Merkle root of all the leaves at a desired depth.
  /// @dev merge() or merged(_depth) must be called first.
  /// @param _depth The depth of the main tree. It must first be computed
  ///               using mergeSubRoots() and merge().
  /// @return mainRoot The root of the main tree.
  function getMainRoot(uint256 _depth) public view returns (uint256 mainRoot) {
    if (hashLength ** _depth < numLeaves) revert DepthTooSmall(_depth, numLeaves);

    mainRoot = mainRoots[_depth];
  }

  /// @notice Get the next subroot index and the current subtree index.
  function getSrIndices() public view returns (uint256 next, uint256 current) {
    next = nextSubRootIndex;
    current = currentSubtreeIndex;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IPoll } from "../interfaces/IPoll.sol";

/// @title CommonUtilities
/// @notice A contract that holds common utilities
/// which are to be used by multiple contracts
/// namely Tally and MessageProcessor
contract CommonUtilities {
  error VotingPeriodNotPassed();

  /// @notice common function for MessageProcessor, and Tally
  /// @param _poll the poll to be checked
  function _votingPeriodOver(IPoll _poll) internal view {
    (uint256 deployTime, uint256 duration) = _poll.getDeployTimeAndDuration();
    // Require that the voting period is over
    uint256 secondsPassed = block.timestamp - deployTime;
    if (secondsPassed <= duration) {
      revert VotingPeriodNotPassed();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DomainObjs
/// @notice An utility contract that holds
/// a number of domain objects and functions
contract DomainObjs {
  /// @notice the length of a MACI message
  uint8 public constant MESSAGE_DATA_LENGTH = 10;

  /// @notice voting modes
  enum Mode {
    QV,
    NON_QV
  }

  /// @title Message
  /// @notice this struct represents a MACI message
  /// @dev msgType: 1 for vote message, 2 for topup message (size 2)
  struct Message {
    uint256 msgType;
    uint256[MESSAGE_DATA_LENGTH] data;
  }

  /// @title PubKey
  /// @notice A MACI public key
  struct PubKey {
    uint256 x;
    uint256 y;
  }

  /// @title StateLeaf
  /// @notice A MACI state leaf
  /// @dev used to represent a user's state
  /// in the state Merkle tree
  struct StateLeaf {
    PubKey pubKey;
    uint256 voiceCreditBalance;
    uint256 timestamp;
  }
}