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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IFactory {
    function totalDeployed() external view returns (uint256 length);
    function deployInfo(uint256 id) external view returns (address token, address nft, address gumbar, bool _allowed);
}

interface IBondingCurve {
    function currentPrice() external view returns (uint256);
    function buy(uint256 _amountBASE, uint256 _minGBT, uint256 expireTimestamp) external;
    function sell(uint256 _amountGBT, uint256 _minETH, uint256 expireTimestamp) external;
    function BASE_TOKEN() external view returns (address);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function XGBT() external view returns (address);
    function initial_totalSupply() external view returns (uint256);
    function reserveGBT() external view returns (uint256);
    function borrowCredit(address user) external view returns (uint256);
    function debt(address user) external view returns (uint256);
    function reserveVirtualBASE() external view returns (uint256);
    function reserveRealBASE() external view returns (uint256);
    function floorPrice() external view returns (uint256);
    function mustStayGBT(address user) external view returns (uint256);
}

interface IGumball {
    function approve(address to, uint256 tokenId) external;
    function swapForExact(uint256[] memory id) external;
    function swap(uint256 _amount) external;
    function redeem(uint256[] memory _id) external;
    function gumballs() external view returns (uint256[] memory arr);
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function contractURI() external view returns (string memory);
    function bFee() external view returns (uint256);
}

interface IGumbar {
    function GBTperXGBT() external view returns (uint256);
    function gumballsDeposited(address user) external view returns (uint256, uint256[] memory);
    function balanceOfNFT(address user) external view returns (uint256, uint256[] memory);
    function getRewardForDuration(address _rewardsToken) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function rewardTokens() external view returns (address[] memory);
    function earned(address account, address _rewardsToken) external view returns (uint256);
}

contract Multicall {

    address factory;

    struct Response {
        uint256 ethRewardForDuration;
        uint256 gbtRewardForDuration;
        uint256 currentPrice;
        uint256 totalSupply;
    }

    struct RewardData {
        address rewardToken;
        string symbol;
    }

    struct UserData {
        // General
        uint256 currentPrice;
        uint256 ltv;
        // Base token
        address baseToken;
        string baseSymbol;
        string baseName;
        uint256 baseBal;
        // ERC20BondingCurve
        uint256 gbtBalanceOfUser;
        uint256 gbtTotalSupply;
        uint256 redemptionFee;
        // Gumbar
        uint256 gbtStaked;
        uint256 ethEarned;
        uint256 gbtEarned;
        uint256 mustStayGBT;
        RewardData[] rewardData;
        uint256[] stakedGumballs;
        uint256[] unstakedGumballs;
        // Available borrow
        uint256 borrowCredit;
        uint256 debt;
        // Reserve values
        uint256 virtualBase;
        uint256 reserveRealBase;
        uint256 reserveGBT;
        // APR calculation values
        uint256 ethRewardForDuration;
        uint256 gbtRewardForDuration;
        uint256 totalSupply;
    }

    struct CollectionData {
        uint256 deploymentIndex;
        address baseToken;
        string baseTokenSymbol;
        string contractURI;
        uint256 currentPrice;
    }

    constructor(
        address _factory
    ) {
        factory = _factory;
    }

    function call(address[] memory collections) external view returns (Response[] memory response) {

        Response[] memory r = new Response[](collections.length);

        for (uint256 i = 0; i < collections.length; i++) {
            (uint256 index, bytes14 kind) = findDeployment(collections[i]);

            if (kind == bytes14("token")) {
                address gumbar = IBondingCurve(collections[i]).XGBT();
                r[i].ethRewardForDuration = IGumbar(gumbar).getRewardForDuration(IBondingCurve(collections[i]).BASE_TOKEN());
                r[i].gbtRewardForDuration = IGumbar(gumbar).getRewardForDuration(collections[i]);
                r[i].currentPrice = IBondingCurve(collections[i]).currentPrice();
                r[i].totalSupply = IGumbar(gumbar).totalSupply();
            }

            if (kind == bytes14("gumball")) {
                (address gbt, , , ) = IFactory(factory).deployInfo(index);
                ( , , address gumbar, ) = IFactory(factory).deployInfo(index);
                r[i].ethRewardForDuration = IGumbar(gumbar).getRewardForDuration(IBondingCurve(gbt).BASE_TOKEN());
                r[i].gbtRewardForDuration = IGumbar(gumbar).getRewardForDuration(gbt);
                r[i].currentPrice = IBondingCurve(gbt).currentPrice();
                r[i].totalSupply = IGumbar(gumbar).totalSupply();
            }
        }

        return r;
    }

    function _gbtPerEth(address collection) public view returns (uint256) {
        
        uint256 GBTperETH = IBondingCurve(collection).reserveGBT() * 1e18 / (IBondingCurve(collection).reserveVirtualBASE() + IBondingCurve(collection).reserveRealBASE());

        return GBTperETH;
    }

    function collectionData(address[] memory gbtAddressForCollection) external view returns (CollectionData[] memory _collectionData) {
        
        CollectionData[] memory cd = new CollectionData[](gbtAddressForCollection.length);

        for (uint256 j = 0; j < gbtAddressForCollection.length; j++) {

            for (uint256 i = 0; i < IFactory(factory).totalDeployed(); i++) {

            (address gbt, address gnft, , ) = IFactory(factory).deployInfo(i);

                if (gbt == gbtAddressForCollection[j]) {
                    cd[j].deploymentIndex = i;
                    cd[j].baseToken = IBondingCurve(gbtAddressForCollection[j]).BASE_TOKEN();
                    cd[j].baseTokenSymbol = ERC20(cd[j].baseToken).symbol();
                    cd[j].contractURI = IGumball(gnft).contractURI();
                    cd[j].currentPrice = IBondingCurve(gbtAddressForCollection[j]).currentPrice();
                }
            }
        }
        
        return cd;
    }

    function userData(address user, address gbtAddressForCollection) external view returns (UserData memory userdata) {

        UserData memory u;

        (uint256 index, ) = findDeployment(gbtAddressForCollection);

            (address gbt, address gumball , address gumbar , ) = IFactory(factory).deployInfo(index); 
            IERC20 base = IERC20(IBondingCurve(gbt).BASE_TOKEN());

            u.currentPrice = IBondingCurve(gbt).currentPrice();

            if (IBondingCurve(gbt).debt(user) == 0 || user == address(0x0000000000000000000000000000000000000000)) {
                u.ltv = 0;
            } else {
                u.ltv = 100 * IBondingCurve(gbt).debt(user) * _gbtPerEth(gbt) / (IGumbar(gumbar).balanceOf(user));
            }

            u.baseToken = address(base);
            u.baseSymbol = ERC20(address(base)).symbol();
            u.baseName = ERC20(address(base)).name();
            u.gbtTotalSupply = IERC20(gbt).totalSupply();
            u.redemptionFee = IGumball(gumball).bFee();
            u.gbtStaked = IGumbar(address(gumbar)).balanceOf(user);
            u.ethEarned = IGumbar(address(gumbar)).earned(user, u.baseToken);
            u.gbtEarned = IGumbar(address(gumbar)).earned(user, address(gbt));

            address[] memory tok = IGumbar(address(gumbar)).rewardTokens();
 
            RewardData[] memory rd = new RewardData[](tok.length);

            for (uint256 i = 0; i < tok.length; i++) {
                rd[i].rewardToken = tok[i];
                rd[i].symbol = ERC20(tok[i]).symbol();
            }

            u.rewardData = rd;
            
            ( , uint256[] memory arr) = IGumbar(address(gumbar)).balanceOfNFT(user);

            if (arr.length == 0) {
                // do nothing
            } else {
                u.stakedGumballs = arr;
            }
            
            uint256[] memory tokenIds = new uint256[](IERC721(gumball).balanceOf(user));

            if (IERC721(gumball).balanceOf(user) == 0) {
                uint256[] memory empty;
                u.unstakedGumballs = empty;
            } else {
                for (uint256 i = 0; i < IERC721(gumball).balanceOf(user); i++) {
                    tokenIds[i] = IGumball(gumball).tokenOfOwnerByIndex(user, i);
                }
                u.unstakedGumballs = tokenIds;
            }
            
            u.virtualBase = IBondingCurve(address(gbt)).reserveVirtualBASE();
            u.reserveRealBase = IBondingCurve(address(gbt)).reserveRealBASE();
            u.reserveGBT = IBondingCurve(address(gbt)).reserveGBT();

            u.ethRewardForDuration = IGumbar(gumbar).getRewardForDuration(IBondingCurve(address(gbt)).BASE_TOKEN());
            u.gbtRewardForDuration = IGumbar(gumbar).getRewardForDuration(address(gbt));
            u.totalSupply = IGumbar(gumbar).totalSupply();

            if (user == address(0x0000000000000000000000000000000000000000)) {
                u.baseBal = 0;
                u.gbtBalanceOfUser = 0;
                u.mustStayGBT = 0;
                u.borrowCredit = 0;
                u.debt = 0;
            } else {
                u.baseBal = base.balanceOf(user);
                u.gbtBalanceOfUser = IERC20(gbt).balanceOf(user);
                u.mustStayGBT = IBondingCurve(address(gbt)).mustStayGBT(user);
                u.borrowCredit = IBondingCurve(address(gbt)).borrowCredit(user);
                u.debt = IBondingCurve(address(gbt)).debt(user);
            }

        return u;
    }

    function totalCollections() public view returns (uint256) {
        return IFactory(factory).totalDeployed();
    }

    function findDeployment(address toFind) public view returns (uint256 _index, bytes14 _type) {

        bool found = false;

        for(uint256 i = 0; i < IFactory(factory).totalDeployed(); i++) {

            (address gbt, , , ) = IFactory(factory).deployInfo(i);
            (, address gumball, , ) = IFactory(factory).deployInfo(i);
            
            if (gbt == toFind) {
                found = true;
                return (i, bytes14('token'));
            } else if (gumball == toFind) {
                found = true;
                return (i, bytes14('gumball'));
            }
        }

        if (!found) {
            revert ('Address not found!');
        }
    }
}