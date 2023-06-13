// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * DeDeLend
 * Copyright (C) 2023 DeDeLend
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IHegicStrategy.sol";

interface ILyra {
    enum OptionType {
        LONG_CALL,
        LONG_PUT,
        SHORT_CALL_BASE,
        SHORT_CALL_QUOTE,
        SHORT_PUT_QUOTE
    }

    struct Result {
        uint positionId;
        uint totalCost;
        uint totalFee;
    }

    struct TradeInputParameters {
        // id of strike
        uint strikeId;
        // OptionToken ERC721 id for position (set to 0 for new positions)
        uint positionId;
        // number of sub-orders to break order into (reduces slippage)
        uint iterations;
        // type of option to trade
        OptionType optionType;
        // number of contracts to trade
        uint amount;
        // final amount of collateral to leave in OptionToken position
        uint setCollateralTo;
        // revert trade if totalCost is below this value
        uint minTotalCost;
        // revert trade if totalCost is above this value
        uint maxTotalCost;
        // referrer emitted in Trade event, no on-chain interaction
        address referrer;
    }

    function openPosition(TradeInputParameters memory params) external returns (Result memory result);
    function closePosition(TradeInputParameters memory params) external returns (Result memory result);
    function quoteAsset() external view returns(ERC20);
    function baseAsset() external view returns(ERC20);
}

interface IOptionToken is IERC721 {
    function nextId() external view returns (uint256);
}

interface IOperationalTreasury {
    function buy(
        IHegicStrategy strategy,
        address holder,
        uint256 amount,
        uint256 period,
        bytes[] calldata additional
    ) external;

    function payOff(uint256 positionID, address account) external;
}

interface IPositionsManager is IERC721 {
    function nextTokenId() external view returns (uint256);
}

abstract contract BaseOptionBuilder is Ownable{
    
    // Enumeration of different protocol types
    enum ProtocolType {
        lyra_eth,
        lyra_btc,
        hegic
    }

    // State variables
    address public lyra_eth; // Address of Lyra ETH contract
    address public lyra_btc; // Address of Lyra BTC contract
    address public operationalTreasury; // Address of operational treasury

    address public lyra_ethErc721; // Address of Lyra ETH ERC721 token contract
    address public lyra_btcErc721; // Address of Lyra BTC ERC721 token contract
    address public hegicErc721; // Address of Hegic ERC721 token contract

    address public usdc; // Address of USDC ERC20 token contract

    uint256 public nextBuildID = 1;

    // Constructor
    constructor (
        address _lyra_eth,
        address _lyra_btc,
        address _operationalTreasury,
        address _lyra_ethErc721,
        address _lyra_btcErc721,
        address _hegicErc721,
        address _usdc
    ) {
        lyra_eth = _lyra_eth;
        lyra_btc = _lyra_btc;
        operationalTreasury = _operationalTreasury;
        lyra_ethErc721 = _lyra_ethErc721;
        lyra_btcErc721 = _lyra_btcErc721;
        hegicErc721 = _hegicErc721;
        usdc = _usdc;
    }

    event CreateBuild(
        uint256 buildID,
        address indexed user,
        uint256 productType
    );

    // Approve maximum spending limits for tokens used in the contract
    function allApprove() external {
        ILyra(lyra_eth).quoteAsset().approve(lyra_eth, type(uint256).max);
        ILyra(lyra_eth).baseAsset().approve(lyra_eth, type(uint256).max);
        ILyra(lyra_btc).quoteAsset().approve(lyra_btc, type(uint256).max);
        ILyra(lyra_btc).baseAsset().approve(lyra_btc, type(uint256).max);
        ERC20(usdc).approve(operationalTreasury, type(uint256).max);
    }

    // Process a transaction using Lyra protocol
    function _processLyraProtocol(
        ProtocolType protocolType,
        bytes memory parametersArray,
        uint256 buildID
    ) internal virtual {}

    // Process a transaction using Hegic protocol
    function _processHegicProtocol(bytes memory parametersArray, uint256 buildID) internal virtual {}

    // Consolidate multiple transactions into a single function call
    function consolidationOfTransactions(ProtocolType[] memory protocolsArrays, bytes[] memory parametersArray, uint256 productType) external {
        require(protocolsArrays.length == parametersArray.length, "arrays not equal");
        
        for (uint i = 0; i < protocolsArrays.length; i++) {
            if (protocolsArrays[i] == ProtocolType.lyra_eth || protocolsArrays[i] == ProtocolType.lyra_btc) {
                _processLyraProtocol(protocolsArrays[i], parametersArray[i], nextBuildID);
            } else if (protocolsArrays[i] == ProtocolType.hegic) {
                _processHegicProtocol(parametersArray[i], nextBuildID);
            }
        }

        emit CreateBuild(nextBuildID, msg.sender, productType);
        nextBuildID++;
    }

    function onERC721Received(
        address, 
        address, 
        uint256, 
        bytes calldata
    )external returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 
}

pragma solidity ^0.8.3;

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2022 Hegic Protocol
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

interface IHegicStrategy {
    event SetLimit(uint256 limit);

    event Acquired(
        uint256 indexed id,
        StrategyData data,
        uint256 negativepnl,
        uint256 positivepnl,
        uint256 period,
        bytes[] additional
    );

    struct StrategyData {
        uint128 amount;
        uint128 strike;
    }

    function strategyData(uint256 strategyID)
        external
        view
        returns (uint128 amount, uint128 strike);

    function getLockedByStrategy() external view returns (uint256 amount);

    function lockedLimit() external view returns (uint256 value);

    function isPayoffAvailable(
        uint256 optID,
        address caller,
        address recipient
    ) external view returns (bool);

    function getAvailableContracts(uint32 period, bytes[] calldata additional)
        external
        view
        returns (uint256 available);

    function payOffAmount(uint256 optionID)
        external
        view
        returns (uint256 profit);

    function calculateNegativepnlAndPositivepnl(
        uint256 amount,
        uint256 period,
        bytes[] calldata
    ) external view returns (uint128 negativepnl, uint128 positivepnl);

    function create(
        uint256 id,
        address holder,
        uint256 amount,
        uint256 period,
        bytes[] calldata
    )
        external
        returns (
            uint32 expiration,
            uint256 positivePNL,
            uint256 negativePNL
        );

    function connect() external;

    function positionExpiration(uint256)
        external
        view
        returns (uint32 timestamp);
}

/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * DeDeLend
 * Copyright (C) 2023 DeDeLend
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 **/

pragma solidity 0.8.9;

import "./BaseOptionBuilder.sol";

contract OptionBuilderOpen is BaseOptionBuilder {

    // Constructor
    constructor(
        address _lyra_eth,
        address _lyra_btc,
        address _operationalTreasury,
        address _lyra_ethErc721,
        address _lyra_btcErc721,
        address _hegicErc721,
        address _usdc
    ) BaseOptionBuilder(
        _lyra_eth,
        _lyra_btc,
        _operationalTreasury,
        _lyra_ethErc721,
        _lyra_btcErc721,
        _hegicErc721,
        _usdc
    ) {}

    // Event emitted when a position is opened using Lyra protocol
    event OpenPositionByLyra(
        uint256 indexed buildID,
        uint256 strikeId,
        uint256 positionId,
        uint256 iterations,
        ILyra.OptionType optionType,
        uint256 amount,
        uint256 setCollateralTo,
        uint256 minTotalCost,
        uint256 maxTotalCost,
        address referrer,
        uint256 tokenID
    );

    // Event emitted when a position is opened using Hegic protocol
    event OpenPositionByHegic(
        uint256 indexed buildID,
        uint256 tokenID,
        address strategy,
        address holder,
        uint256 amount,
        uint256 period,
        uint256 premuim
    );

    function _processLyraProtocol(
        ProtocolType protocolType,
        bytes memory parameters,
        uint256 buildID
    ) override internal {
        (
            ILyra.TradeInputParameters memory params
        ) = decodeFromLyra(parameters);
        
        address lyra = lyra_eth;
        address lyraErc721 = lyra_ethErc721;
        
        // Check the protocol type and set appropriate Lyra and ERC721 token addresses
        if (protocolType == ProtocolType.lyra_btc) {
            lyra = lyra_btc;
            lyraErc721 = lyra_btcErc721;
        }
        
        uint256 premium;
        ERC20 lyraAsset;
        
        // Calculate premium amount and determine Lyra asset based on option type
        if (params.optionType == ILyra.OptionType.LONG_CALL || params.optionType == ILyra.OptionType.LONG_PUT) {
            premium = params.maxTotalCost / (1e18 / 10 ** ILyra(lyra).quoteAsset().decimals());
            lyraAsset = ILyra(lyra).quoteAsset();
        } else if (params.optionType == ILyra.OptionType.SHORT_CALL_QUOTE || params.optionType == ILyra.OptionType.SHORT_PUT_QUOTE) {
            premium = params.setCollateralTo / (1e18 / 10 ** ILyra(lyra).quoteAsset().decimals());
            lyraAsset = ILyra(lyra).quoteAsset();
        } else if (params.optionType == ILyra.OptionType.SHORT_CALL_BASE) {
            premium = params.setCollateralTo / (1e18 / 10 ** ILyra(lyra).baseAsset().decimals());
            lyraAsset = ILyra(lyra).baseAsset();
        }
        
        // Transfer premium amount from sender to the contract
        lyraAsset.transferFrom(msg.sender, address(this), premium);
        
        // Get the next available ERC721 token ID
        uint256 id = IOptionToken(lyraErc721).nextId();
        
        // Open the position using the Lyra contract
        ILyra(lyra).openPosition(params);
        
        // Transfer back remaining tokens to the sender
        lyraAsset.transfer(msg.sender, lyraAsset.balanceOf(address(this)));
        
        // Transfer ERC721 token representing the option to the sender
        IOptionToken(lyraErc721).transferFrom(address(this), msg.sender, id);
        if (params.optionType == ILyra.OptionType.SHORT_CALL_BASE) {
            ILyra(lyra).quoteAsset().transfer(msg.sender, ILyra(lyra).quoteAsset().balanceOf(address(this)));
        }
        
        // Emit the OpenPositionByLyra event with relevant parameters
        emit OpenPositionByLyra(
            buildID,
            params.strikeId,
            params.positionId,
            params.iterations,
            params.optionType,
            params.amount,
            params.setCollateralTo,
            params.minTotalCost,
            params.maxTotalCost,
            params.referrer,
            id
        );
    }

    function _processHegicProtocol(bytes memory parameters, uint256 buildID) internal override {
        (
            IHegicStrategy strategy,
            address holder,
            uint256 amount,
            uint256 period,
            bytes[] memory additional
        ) = decodeFromHegic(parameters);
        
        // Calculate the premium amount from positive pnl using the Hegic strategy
        (, uint128 positivepnl) = strategy.calculateNegativepnlAndPositivepnl(amount, period, additional);
        uint256 premium = uint256(positivepnl);
        
        // Transfer premium amount in USDC from sender to the contract
        ERC20(usdc).transferFrom(msg.sender, address(this), premium);
        
        // Get the next available ERC721 token ID
        uint256 id = IPositionsManager(hegicErc721).nextTokenId() + 1;
        
        // Buy the option using the operational treasury contract
        IOperationalTreasury(operationalTreasury).buy(
            strategy,
            holder,
            amount,
            period,
            additional
        );
        
        // Transfer ERC721 token representing the option to the sender
        IPositionsManager(hegicErc721).transferFrom(address(this), msg.sender, id);
        
        // Emit the OpenPositionByHegic event with relevant parameters
        emit OpenPositionByHegic(buildID, id, address(strategy), holder, amount, period, premium);
    }

    // Encode TradeInputParameters struct into bytes
    function encodeFromLyra(ILyra.TradeInputParameters memory params) external pure returns (bytes memory paramData) {
        return abi.encode(params);
    }

    function decodeFromLyra(bytes memory paramData) public pure returns (ILyra.TradeInputParameters memory params) {
        (
            params
        ) = abi.decode(paramData, (
            ILyra.TradeInputParameters
        ));
    }


    // Encode Hegic parameters into bytes
    function encodeFromHegic(
        IHegicStrategy strategy,
        address holder,
        uint256 amount,
        uint256 period,
        bytes[] memory additional
    ) external pure returns (bytes memory paramData) {
        return abi.encode(strategy, holder, amount, period, additional);
    }

    function decodeFromHegic(
        bytes memory paramData
    ) public pure returns (
        IHegicStrategy strategy,
        address holder,
        uint256 amount,
        uint256 period,
        bytes[] memory additional
    ) {
        (
            strategy,
            holder,
            amount,
            period,
            additional
        ) = abi.decode(paramData, (
            IHegicStrategy,
            address,
            uint256,
            uint256,
            bytes[]
        ));
    }
}