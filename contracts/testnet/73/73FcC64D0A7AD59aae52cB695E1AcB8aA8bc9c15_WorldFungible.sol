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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./Ownable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20 is Ownable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Context.sol";

/**
    https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IWorldModule {
    function moduleID() external view returns (uint256);

    function tokenSVG(uint256 _actor, uint256 _startY, uint256 _lineHeight) external view returns (string memory, uint256 _endY);
    function tokenJSON(uint256 _actor) external view returns (string memory);
}

interface IWorldRandom is IWorldModule {
    function dn(uint256 _actor, uint256 _number) external view returns (uint256);
    function d20(uint256 _actor) external view returns (uint256);
}

interface IActors is IERC721, IWorldModule {

    struct Actor 
    {
        address owner;
        address account;
        uint256 actorId;
    }

    event TaiyiDAOUpdated(address taiyiDAO);
    event ActorMinted(address indexed owner, uint256 indexed actorId, uint256 indexed time);
    event ActorPurchased(address indexed payer, uint256 indexed actorId, uint256 price);

    function actor(uint256 _actor) external view returns (uint256 _mintTime, uint256 _status);
    function nextActor() external view returns (uint256);
    function mintActor(uint256 maxPrice) external returns(uint256 actorId);
    function changeActorRenderMode(uint256 _actor, uint256 _mode) external;
    function setTaiyiDAO(address _taiyiDAO) external;

    function actorPrice() external view returns (uint256);
    function getActor(uint256 _actor) external view returns (Actor memory);
    function getActorByHolder(address _holder) external view returns (Actor memory);
    function getActorsByOwner(address _owner) external view returns (Actor[] memory);
    function isHolderExist(address _holder) external view returns (bool);
}

interface IWorldYemings is IWorldModule {
    event TaiyiDAOUpdated(address taiyiDAO);

    function setTaiyiDAO(address _taiyiDAO) external;

    function YeMings(uint256 _actor) external view returns (address);
    function isYeMing(uint256 _actor) external view returns (bool);
}

interface IWorldTimeline is IWorldModule {

    event AgeEvent(uint256 indexed actor, uint256 indexed age, uint256 indexed eventId);
    event BranchEvent(uint256 indexed actor, uint256 indexed age, uint256 indexed eventId);
    event ActiveEvent(uint256 indexed actor, uint256 indexed age, uint256 indexed eventId);

    function name() external view returns (string memory);
    function description() external view returns (string memory);
    function operator() external view returns (uint256);
    function events() external view returns (IWorldEvents);

    function grow(uint256 _actor) external;
    function activeTrigger(uint256 _eventId, uint256 _actor, uint256[] memory _uintParams, string[] memory _stringParams) external;
}

interface IActorAttributes is IWorldModule {

    event Created(address indexed creator, uint256 indexed actor, uint256[] attributes);
    event Updated(address indexed executor, uint256 indexed actor, uint256[] attributes);

    function setAttributes(uint256 _operator, uint256 _actor, uint256[] memory _attributes) external;
    function pointActor(uint256 _operator, uint256 _actor) external;

    function attributeLabels(uint256 _attributeId) external view returns (string memory);
    function attributesScores(uint256 _attributeId, uint256 _actor) external view returns (uint256);
    function characterPointsInitiated(uint256 _actor) external view returns (bool);
    function applyModified(uint256 _actor, int[] memory _modifiers) external view returns (uint256[] memory, bool);
}

interface IActorBehaviorAttributes is IActorAttributes {

    event ActRecovered(uint256 indexed actor, uint256 indexed act);

    function canRecoverAct(uint256 _actor) external view returns (bool);
    function recoverAct(uint256 _actor) external;
}

interface IActorTalents is IWorldModule {

    event Created(address indexed creator, uint256 indexed actor, uint256[] ids);

    function talents(uint256 _id) external view returns (string memory _name, string memory _description);
    function talentAttributeModifiers(uint256 _id) external view returns (int256[] memory);
    function talentAttrPointsModifiers(uint256 _id, uint256 _attributeModuleId) external view returns (int256);
    function setTalent(uint256 _id, string memory _name, string memory _description, int[] memory _modifiers, int256[] memory _attr_point_modifiers) external;
    function setTalentExclusive(uint256 _id, uint256[] memory _exclusive) external;
    function setTalentProcessor(uint256 _id, address _processorAddress) external;
    function talentProcessors(uint256 _id) external view returns(address);
    function talentExclusivity(uint256 _id) external view returns (uint256[] memory);

    function setActorTalent(uint256 _operator, uint256 _actor, uint256 _tid) external;
    function talentActor(uint256 _operator, uint256 _actor) external; 
    function actorAttributePointBuy(uint256 _actor, uint256 _attributeModuleId) external view returns (uint256);
    function actorTalents(uint256 _actor) external view returns (uint256[] memory);
    function actorTalentsInitiated(uint256 _actor) external view returns (bool);
    function actorTalentsExist(uint256 _actor, uint256[] memory _talents) external view returns (bool[] memory);
    function canOccurred(uint256 _actor, uint256 _id, uint256 _age) external view returns (bool);
}

interface IActorTalentProcessor {
    function checkOccurrence(uint256 _actor, uint256 _age) external view returns (bool);
    function process(uint256 _operator, uint256 _actor, uint256 _age) external;
}

interface IWorldEvents is IWorldModule {

    event Born(uint256 indexed actor);

    function ages(uint256 _actor) external view returns (uint256); //current age
    function actorBorn(uint256 _actor) external view returns (bool);
    function actorBirthday(uint256 _actor) external view returns (bool);
    function expectedAge(uint256 _actor) external view returns (uint256); //age should be
    function actorEvent(uint256 _actor, uint256 _age) external view returns (uint256[] memory);
    function actorEventCount(uint256 _actor, uint256 _eventId) external view returns (uint256);

    function eventInfo(uint256 _id, uint256 _actor) external view returns (string memory);
    function eventAttributeModifiers(uint256 _id, uint256 _actor) external view returns (int256[] memory);
    function eventProcessors(uint256 _id) external view returns(address);
    function setEventProcessor(uint256 _id, address _address) external;
    function canOccurred(uint256 _actor, uint256 _id, uint256 _age) external view returns (bool);
    function checkBranch(uint256 _actor, uint256 _id, uint256 _age) external view returns (uint256);

    function bornActor(uint256 _operator, uint256 _actor) external;
    function grow(uint256 _operator, uint256 _actor) external;
    function changeAge(uint256 _operator, uint256 _actor, uint256 _age) external;
    function addActorEvent(uint256 _operator, uint256 _actor, uint256 _age, uint256 _eventId) external;
}

interface IWorldEventProcessor {
    function eventInfo(uint256 _actor) external view returns (string memory);
    function eventAttributeModifiers(uint256 _actor) external view returns (int[] memory);
    function trigrams(uint256 _actor) external view returns (uint256[] memory);
    function checkOccurrence(uint256 _actor, uint256 _age) external view returns (bool);
    function process(uint256 _operator, uint256 _actor, uint256 _age) external;
    function activeTrigger(uint256 _operator, uint256 _actor, uint256[] memory _uintParams, string[] memory _stringParams) external;

    function checkBranch(uint256 _actor, uint256 _age) external view returns (uint256);
    function setDefaultBranch(uint256 _enentId) external;
}

interface IWorldFungible is IWorldModule {
    event FungibleTransfer(uint256 indexed from, uint256 indexed to, uint256 amount);
    event FungibleApproval(uint256 indexed from, uint256 indexed to, uint256 amount);

    function balanceOfActor(uint256 _owner) external view returns (uint256);
    function allowanceActor(uint256 _owner, uint256 _spender) external view returns (uint256);

    function approveActor(uint256 _from, uint256 _spender, uint256 _amount) external;
    function transferActor(uint256 _from, uint256 _to, uint256 _amount) external;
    function transferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _amount) external;
    function claim(uint256 _operator, uint256 _actor, uint256 _amount) external;
    function withdraw(uint256 _operator, uint256 _actor, uint256 _amount) external;
}

interface IWorldNonfungible {
    event NonfungibleTransfer(uint256 indexed from, uint256 indexed to, uint256 indexed tokenId);
    event NonfungibleApproval(uint256 indexed owner, uint256 indexed approved, uint256 indexed tokenId);
    event NonfungibleApprovalForAll(uint256 indexed owner, uint256 indexed operator, bool approved);

    function tokenOfActorByIndex(uint256 _owner, uint256 _index) external view returns (uint256);
    function balanceOfActor(uint256 _owner) external view returns (uint256);
    function ownerActorOf(uint256 _tokenId) external view returns (uint256);
    function getApprovedActor(uint256 _tokenId) external view returns (uint256);
    function isApprovedForAllActor(uint256 _owner, uint256 _operator) external view returns (bool);

    function approveActor(uint256 _from, uint256 _to, uint256 _tokenId) external;
    function setApprovalForAllActor(uint256 _from, uint256 _operator, bool _approved) external;
    function safeTransferActor(uint256 _from, uint256 _to, uint256 _tokenId, bytes calldata _data) external;
    function safeTransferActor(uint256 _from, uint256 _to, uint256 _tokenId) external;
    function transferActor(uint256 _from, uint256 _to, uint256 _tokenId) external;
    function safeTransferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _tokenId, bytes calldata _data) external;
    function safeTransferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _tokenId) external;
    function transferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _tokenId) external;
}

interface IActorNames is IWorldNonfungible, IERC721Enumerable, IWorldModule {

    event NameClaimed(address indexed owner, uint256 indexed actor, uint256 indexed nameId, string name, string firstName, string lastName);
    event NameUpdated(uint256 indexed nameId, string oldName, string newName);
    event NameAssigned(uint256 indexed nameId, uint256 indexed previousActor, uint256 indexed newActor);

    function nextName() external view returns (uint256);
    function actorName(uint256 _actor) external view returns (string memory _name, string memory _firstName, string memory _lastName);

    function claim(string memory _firstName, string memory _lastName, uint256 _actor) external returns (uint256 _nameId);
    function assignName(uint256 _nameId, uint256 _actor) external;
    function withdraw(uint256 _operator, uint256 _actor) external;
}

interface IWorldZones is IWorldNonfungible, IERC721Enumerable, IWorldModule {

    event ZoneClaimed(uint256 indexed actor, uint256 indexed zoneId, string name);
    event ZoneUpdated(uint256 indexed zoneId, string oldName, string newName);
    event ZoneAssigned(uint256 indexed zoneId, uint256 indexed previousActor, uint256 indexed newActor);

    function nextZone() external view returns (uint256);
    function names(uint256 _zoneId) external view returns (string memory);
    function timelines(uint256 _zoneId) external view returns (address);

    function claim(uint256 _operator, string memory _name, address _timelineAddress, uint256 _actor) external returns (uint256 _zoneId);
    function withdraw(uint256 _operator, uint256 _zoneId) external;
}

interface IActorBornPlaces is IWorldModule {
    function bornPlaces(uint256 _actor) external view returns (uint256);
    function bornActor(uint256 _operator, uint256 _actor, uint256 _zoneId) external;
}

interface IActorSocialIdentity is IWorldNonfungible, IERC721Enumerable, IWorldModule {
    event SIDClaimed(uint256 indexed actor, uint256 indexed sid, string name);
    event SIDDestroyed(uint256 indexed actor, uint256 indexed sid, string name);

    function nextSID() external view returns (uint256);
    function names(uint256 _nameid) external view returns (string memory);
    function claim(uint256 _operator, uint256 _nameid, uint256 _actor) external returns (uint256 _sid);
    function burn(uint256 _operator, uint256 _sid) external;
    function sidName(uint256 _sid) external view returns (uint256 _nameid, string memory _name);
    function haveName(uint256 _actor, uint256 _nameid) external view returns (bool);
}

interface IActorRelationship is IWorldModule {
    event RelationUpdated(uint256 indexed actor, uint256 indexed target, uint256 indexed rsid, string rsname);

    function relations(uint256 _rsid) external view returns (string memory);
    function setRelation(uint256 _rsid, string memory _name) external;
    function setRelationProcessor(uint256 _rsid, address _processorAddress) external;
    function relationProcessors(uint256 _id) external view returns(address);

    function setActorRelation(uint256 _operator, uint256 _actor, uint256 _target, uint256 _rsid) external;
    function actorRelations(uint256 _actor, uint256 _target) external view returns (uint256);
    function actorRelationPeople(uint256 _actor, uint256 _rsid) external view returns (uint256[] memory);
}

interface IActorRelationshipProcessor {
    function process(uint256 _actor, uint256 _age) external;
}

struct SItem 
{
    uint256 typeId;
    string typeName;
    uint256 shapeId;
    string shapeName;
    uint256 wear;
}

interface IWorldItems is IWorldNonfungible, IERC721Enumerable, IWorldModule {
    event ItemCreated(uint256 indexed actor, uint256 indexed item, uint256 indexed typeId, string typeName, uint256 wear, uint256 shape, string shapeName);
    event ItemChanged(uint256 indexed actor, uint256 indexed item, uint256 indexed typeId, string typeName, uint256 wear, uint256 shape, string shapeName);
    event ItemDestroyed(uint256 indexed item, uint256 indexed typeId, string typeName);

    function nextItemId() external view returns (uint256);
    function typeNames(uint256 _typeId) external view returns (string memory);
    function itemTypes(uint256 _itemId) external view returns (uint256);
    function itemWears(uint256 _itemId) external view returns (uint256);  //耐久
    function shapeNames(uint256 _shapeId) external view returns (string memory);
    function itemShapes(uint256 _itemId) external view returns (uint256); //品相

    function item(uint256 _itemId) external view returns (SItem memory);

    function mint(uint256 _operator, uint256 _typeId, uint256 _wear, uint256 _shape, uint256 _actor) external returns (uint256);
    function modify(uint256 _operator, uint256 _itemId, uint256 _wear) external;
    function burn(uint256 _operator, uint256 _itemId) external;
    function withdraw(uint256 _operator, uint256 _itemId) external;
}

interface IActorPrelifes is IWorldModule {

    event Reincarnation(uint256 indexed actor, uint256 indexed postLife);

    function preLifes(uint256 _actor) external view returns (uint256);
    function postLifes(uint256 _actor) external view returns (uint256);

    function setPrelife(uint256 _operator, uint256 _actor, uint256 _prelife) external;
}

interface IWorldSeasons is IWorldModule {

    function seasonLabels(uint256 _seasonId) external view returns (string memory);
    function actorBornSeasons(uint256 _actor) external view returns (uint256); // =0 means not born

    function bornActor(uint256 _operator, uint256 _actor, uint256 _seasonId) external;
}

interface IWorldZoneBaseResources is IWorldModule {

    event ZoneAssetGrown(uint256 indexed zone, uint256 gold, uint256 food, uint256 herb, uint256 fabric, uint256 wood);
    event ActorAssetCollected(uint256 indexed actor, uint256 gold, uint256 food, uint256 herb, uint256 fabric, uint256 wood);

    function ACTOR_GUANGONG() external view returns (uint256);

    function growAssets(uint256 _operator, uint256 _zoneId) external;
    function collectAssets(uint256 _operator, uint256 _actor, uint256 _zoneId) external;
}

interface IActorLocations is IWorldModule {

    event ActorLocationChanged(uint256 indexed actor, uint256 indexed oldA, uint256 indexed oldB, uint256 newA, uint256 newB);

    function locationActors(uint256 _A, uint256 _B) external view returns (uint256[] memory);
    function actorLocations(uint256 _actor) external view returns (uint256[] memory); //return 2 items array
    function actorFreeTimes(uint256 _actor) external view returns (uint256);
    function isActorLocked(uint256 _actor) external view returns (bool);
    function isActorUnlocked(uint256 _actor) external view returns (bool);

    function setActorLocation(uint256 _operator, uint256 _actor, uint256 _A, uint256 _B) external;
    function lockActor(uint256 _operator, uint256 _actor, uint256 _freeTime) external;
    function unlockActor(uint256 _operator, uint256 _actor) external;
    function finishActorTravel(uint256 _actor) external;
}

interface IWorldVillages is IWorldModule {
    function isZoneVillage(uint256 _zoneId) external view returns (bool);
    function villageCreators(uint256 _zoneId) external view returns (uint256);

    function createVillage(uint256 _operator, uint256 _actor, uint256 _zoneId) external;
}

//building is an item
interface IWorldBuildings is IWorldModule {

    function typeNames(uint256 _typeId) external view returns (string memory);
    function buildingTypes(uint256 _zoneId) external view returns (uint256);
    function isZoneBuilding(uint256 _zoneId) external view returns (bool);

    function createBuilding(uint256 _operator, uint256 _actor, uint256 _typeId, uint256 _zoneId) external;
}

interface ITrigramsRender is IWorldModule {
}

interface ITrigrams is IWorldModule {
    
    event TrigramsOut(uint256 indexed actor, uint256 indexed trigram);

    function addActorTrigrams(uint256 _operator, uint256 _actor, uint256[] memory _trigramsData) external;
    function actorTrigrams(uint256 _actor) external view returns (int256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library WorldConstants {

    //special actors ID
    uint256 public constant ACTOR_PANGU = 1;

    //actor attributes ID
    uint256 public constant ATTR_BASE = 0;
    uint256 public constant ATTR_AGE = 0; // 年龄
    uint256 public constant ATTR_HLH = 1; // 健康，生命

    //module ID
    uint256 public constant WORLD_MODULE_ACTORS       = 0;  //角色
    uint256 public constant WORLD_MODULE_RANDOM       = 1;  //随机数
    uint256 public constant WORLD_MODULE_NAMES        = 2;  //姓名
    uint256 public constant WORLD_MODULE_COIN         = 3;  //通货
    uint256 public constant WORLD_MODULE_YEMINGS      = 4;  //噎明权限
    uint256 public constant WORLD_MODULE_ZONES        = 5;  //区域
    uint256 public constant WORLD_MODULE_SIDS         = 6;  //身份
    uint256 public constant WORLD_MODULE_ITEMS        = 7;  //物品
    uint256 public constant WORLD_MODULE_PRELIFES     = 8;  //前世
    uint256 public constant WORLD_MODULE_ACTOR_LOCATIONS    = 9;  //角色定位

    uint256 public constant WORLD_MODULE_TRIGRAMS_RENDER    = 10; //角色符文渲染器
    uint256 public constant WORLD_MODULE_TRIGRAMS           = 11; //角色符文数据

    uint256 public constant WORLD_MODULE_SIFUS        = 12; //师傅令牌
    uint256 public constant WORLD_MODULE_ATTRIBUTES   = 13; //角色基本属性
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./WorldContractRoute.sol";

contract WorldConfigurable
{
    WorldContractRoute internal worldRoute;

    modifier onlyApprovedOrOwner(uint _actor) {
        require(_isActorApprovedOrOwner(_actor), "not approved or owner of actor");
        _;
    }

    modifier onlyPanGu() {
        require(_isActorApprovedOrOwner(WorldConstants.ACTOR_PANGU), "only PanGu");
        _;
    }

    modifier onlyYeMing(uint256 _actor) {
        require(IWorldYemings(worldRoute.modules(WorldConstants.WORLD_MODULE_YEMINGS)).isYeMing(_actor), "only YeMing");
        require(_isActorApprovedOrOwner(_actor), "not YeMing's operator");
        _;
    }

    constructor(WorldContractRoute _route) {
        worldRoute = _route;
    }

    function _isActorApprovedOrOwner(uint _actor) internal view returns (bool) {
        IActors actors = worldRoute.actors();
        return (actors.getApproved(_actor) == msg.sender || actors.ownerOf(_actor) == msg.sender) || actors.isApprovedForAll(actors.ownerOf(_actor), msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/WorldInterfaces.sol";
import "../libs/WorldConstants.sol";
import "../base/Ownable.sol";

contract WorldContractRoute is Ownable
{ 
    uint256 public constant ACTOR_PANGU = 1;
    
    mapping(uint256 => address) public modules;
    address                     public actorsAddress;
    IActors                     public actors;
 
    /* *********
     * Modifiers
     * *********
     */

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "cannot set zero address");
        _;
    }

    modifier onlyPanGu() {
        require(_isActorApprovedOrOwner(ACTOR_PANGU), "only PanGu");
        _;
    }

    /* ****************
     * Internal Functions
     * ****************
     */

    function _isActorApprovedOrOwner(uint256 _actor) internal view returns (bool) {
        return (actors.getApproved(_actor) == msg.sender || actors.ownerOf(_actor) == msg.sender) || actors.isApprovedForAll(actors.ownerOf(_actor), msg.sender);
    }

    /* ****************
     * External Functions
     * ****************
     */

    function registerActors(address _address) external 
        onlyOwner
        onlyValidAddress(_address)
    {
        require(actorsAddress == address(0), "Actors address already registered.");
        actorsAddress = _address;
        actors = IActors(_address);
        modules[WorldConstants.WORLD_MODULE_ACTORS] = _address;
    }

    function registerModule(uint256 id, address _address) external 
        onlyPanGu
        onlyValidAddress(_address)
    {
        //require(modules[id] == address(0), "module address already registered.");
        require(IWorldModule(_address).moduleID() == id, "module id is not match.");
        modules[id] = _address;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/WorldInterfaces.sol";
import "../base/ERC20.sol";
import "./WorldConfigurable.sol";

contract WorldFungible is IWorldFungible, ERC20, WorldConfigurable {

    uint256 public override moduleID;

    constructor(string memory _name, string memory _symbol, uint256 _moduleID, WorldContractRoute _route) ERC20(_name, _symbol) WorldConfigurable(_route) {
        moduleID = _moduleID;
    }

    /* ****************
     * Public Functions
     * ****************
     */

    function claim(uint256 _operator, uint256 _actor, uint256 _amount) public virtual override
        onlyYeMing(_operator)
    {
        require(_amount > 0, "amount must not be zero");
        _mint(worldRoute.actors().getActor(_actor).account, _amount);
        emit FungibleTransfer(0, _actor, _amount);
    }

    function approveActor(uint256 _from, uint256 _spender, uint256 _amount) public virtual override
        onlyApprovedOrOwner(_from)
    {
        address _fromAccount = worldRoute.actors().getActor(_from).account;
        address _spenderAccount = worldRoute.actors().getActor(_spender).account;
        _approve(_fromAccount, _spenderAccount, _amount);
        emit FungibleApproval(_from, _spender, _amount);
    }

    function transferActor(uint256 _from, uint256 _to, uint256 _amount) public virtual override
        onlyApprovedOrOwner(_from)
    {
        address _fromAccount = worldRoute.actors().getActor(_from).account;
        address _toAccount = worldRoute.actors().getActor(_to).account;
        _transfer(_fromAccount, _toAccount, _amount);
        emit FungibleTransfer(_from, _to, _amount);
    }

    function transferFromActor(uint256 _executor, uint256 _from, uint256 _to, uint256 _amount) public virtual override
        onlyApprovedOrOwner(_executor)
    {
        address _fromAccount = worldRoute.actors().getActor(_from).account;
        address _toAccount = worldRoute.actors().getActor(_to).account;
        address _spenderAccount = worldRoute.actors().getActor(_executor).account;

        _transfer(_fromAccount, _toAccount, _amount);
        emit FungibleTransfer(_from, _to, _amount);

        uint256 _currentAllowance = _allowances[_fromAccount][_spenderAccount];        
        if (_spenderAccount != _fromAccount && _currentAllowance != type(uint).max) {
            require(_currentAllowance >= _amount, "transfer amount exceeds allowance");
            uint256 _newAllowance = _currentAllowance - _amount;
            unchecked {
                _approve(_fromAccount, _spenderAccount, _newAllowance);
            }
            emit FungibleApproval(_from, _executor, _newAllowance);
        }
    }

    function withdraw(uint256 _operator, uint256 _actor, uint256 _amount) public virtual override
        onlyYeMing(_operator)
        onlyApprovedOrOwner(_actor)
    {
        address _actorOwner = worldRoute.actors().getActor(_actor).owner;
        address _actorHolder = worldRoute.actors().getActor(_actor).account;

        _transfer(_actorHolder, _actorOwner, _amount);
        emit FungibleTransfer(_actor, 0, _amount); //actor #0 is not exist, so means withdraw and not burnt
    }

    /* **************
     * View Functions
     * **************
     */
    function balanceOfActor(uint256 _owner) external override view returns (uint256) {
        return balanceOf(worldRoute.actors().getActor(_owner).account);
    }

    function allowanceActor(uint256 _owner, uint256 _spender) external override view returns (uint256) {
        return allowance(worldRoute.actors().getActor(_owner).account, worldRoute.actors().getActor(_spender).account);
    }

    function tokenSVG(uint256 /*_actor*/, uint256 /*_startY*/, uint256 /*_lineHeight*/) public virtual override view returns (string memory, uint256 endY) {
        return ("", endY);
    }

    function tokenJSON(uint256 /*_actor*/) public virtual override view returns (string memory) {
        return "{}";
    }
}