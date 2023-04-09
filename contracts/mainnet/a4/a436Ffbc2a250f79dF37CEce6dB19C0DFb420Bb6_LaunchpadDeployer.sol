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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
pragma solidity ^0.8.0;

import "./IEnums.sol";

interface IDeployer {
    function addToUserLaunchpad(
        address _user,
        address _token,
        IEnums.LAUNCHPAD_TYPE _launchpadType
    ) external;

    function changeLaunchpadState(address _token, uint256 _newState) external;

    function changeActionChanged(
        address _launchpad,
        bool _usingWhitelist,
        uint256 _endOfWhitelistTime
    ) external;

    function changeWhitelistUsers(
        address _launchpad,
        address[] memory _users,
        uint256 _action
    ) external;

    function launchpadRaisedAmountChangedReport(
        address _token,
        uint256 _currentRaisedAmount,
        uint256 _currentNeedToRaised
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEnums {
    enum LAUNCHPAD_TYPE {
        NORMAL,
        FAIR
    }

    enum LAUNCHPAD_STATE {
        OPENING,
        FINISHED,
        CANCELLED
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IDeployer.sol";

contract LaunchPad is Ownable, Pausable, ReentrancyGuard, IEnums {
    //variables for oprating sale
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public startTime;
    uint256 public endOfWhitelistTime;
    uint256 public endTime;
    uint256 public endSaleTime;
    uint256 public listingRate;
    uint256 public presaleRate;
    uint256 public maxBuyPerParticipant;
    uint256 public minBuyPerParticipant;
    string public URIData;
    address public tokenSale;
    address public tokenPayment;
    address public admin;
    uint256 public adminTokenPaymentFee;
    uint256 public adminTokenSaleFee;
    bool public usingWhitelist;
    bool public refundWhenFinish = true;

    //variable for display data
    uint256 public totalDeposits;
    uint256 public totalRaised;
    uint256 public totalNeedToRaised;
    uint256 public contributorId;
    uint256 public status;
    IDeployer deployer;
    IEnums.LAUNCHPAD_TYPE launchPadType;
    mapping(address => uint256) public depositedAmount;
    mapping(address => uint256) public earnedAmount;
    mapping(uint256 => address) public contributorsList;
    mapping(address => bool) public whitelist;

    event userDeposit(uint256 amount, address user);
    event userRefunded(uint256 amount, address user);
    event userClaimed(uint256 amount, address user);
    event saleClosed(uint256 timeStamp, uint256 collectedAmount);
    event saleCanceled(uint256 timeStamp, address operator);

    constructor(
        uint256[2] memory _caps,
        uint256[3] memory _times,
        uint256[2] memory _rates,
        uint256[2] memory _limits,
        uint256[2] memory _adminFees,
        address[2] memory _tokens,
        string memory _URIData,
        address _admin,
        bool _refundWhenFinish,
        IEnums.LAUNCHPAD_TYPE _launchpadType
    ) {
        softCap = _caps[0];
        hardCap = _caps[1];
        startTime = _times[0];
        endTime = _times[1];
        endSaleTime = _times[2];
        URIData = _URIData;
        adminTokenSaleFee = _adminFees[0];
        adminTokenPaymentFee = _adminFees[1];
        tokenSale = _tokens[0];
        tokenPayment = _tokens[1];
        admin = _admin;
        presaleRate = _rates[0];
        listingRate = _rates[1];
        maxBuyPerParticipant = _limits[1];
        minBuyPerParticipant = _limits[0];
        refundWhenFinish = _refundWhenFinish;
        launchPadType = _launchpadType;
        deployer = IDeployer(msg.sender);
    }

    modifier restricted() {
        require(
            msg.sender == owner() || msg.sender == admin,
            "Launchpad: Caller not allowed"
        );
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Launchpad: Caller not admin");
        _;
    }

    function invest(uint256 _amount) external payable nonReentrant {
        _checkCanInvest(msg.sender);
        require(
            status == uint256(IEnums.LAUNCHPAD_STATE.OPENING),
            "Launchpad: Sale is not open"
        );
        require(startTime < block.timestamp, "Launchpad: Sale is not open yet");
        require(endTime > block.timestamp, "Launchpad: Sale is already closed");

        if (launchPadType == LAUNCHPAD_TYPE.NORMAL) {
            require(
                _amount + totalDeposits <= hardCap,
                "Launchpad(Normal): Hardcap reached"
            );
        }
        if (tokenPayment == address(0)) {
            require(_amount == msg.value, "Launchpad: Invalid payment amount");
        } else {
            IERC20(tokenPayment).transferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }
        if (depositedAmount[msg.sender] == 0) {
            contributorsList[contributorId] = msg.sender;
            contributorId++;
        }
        depositedAmount[msg.sender] += _amount;
        if (launchPadType == IEnums.LAUNCHPAD_TYPE.NORMAL) {
            require(
                depositedAmount[msg.sender] >= minBuyPerParticipant,
                "Launchpad: Min contribution not reached"
            );
            require(
                depositedAmount[msg.sender] <= maxBuyPerParticipant,
                "Launchpad: Max contribution not reached"
            );
            uint256 tokenRaised = (_amount *
                presaleRate *
                10**ERC20(tokenSale).decimals()) / 10**18;
            totalRaised += tokenRaised;
            totalNeedToRaised += tokenRaised;
            earnedAmount[msg.sender] += tokenRaised;
        }
        totalDeposits += _amount;
        deployer.addToUserLaunchpad(
            msg.sender,
            tokenSale,
            IEnums.LAUNCHPAD_TYPE.NORMAL
        );
        deployer.launchpadRaisedAmountChangedReport(tokenSale, totalDeposits, totalNeedToRaised);
        emit userDeposit(_amount, msg.sender);
    }

    function claimFund() external nonReentrant {
        _checkCanClaimFund();
        uint256 amountEarned = 0;
        if (launchPadType == LAUNCHPAD_TYPE.NORMAL) {
            amountEarned = earnedAmount[msg.sender];
            earnedAmount[msg.sender] = 0;
            if (totalNeedToRaised <= amountEarned) {
                totalNeedToRaised = 0;
            } else {
                totalNeedToRaised -= amountEarned;
            }
        } else {
            amountEarned =
                (depositedAmount[msg.sender] * getTotalTokenSale()) /
                totalDeposits;
            depositedAmount[msg.sender] = 0;
        }
        require(amountEarned > 0, "Launchpad: User have no token to claim");
        IERC20(tokenSale).transfer(msg.sender, amountEarned);
        deployer.launchpadRaisedAmountChangedReport(tokenSale, totalDeposits, totalNeedToRaised);
        emit userClaimed(amountEarned, msg.sender);
    }

    function claimRefund() external nonReentrant {
        if (status != uint256(IEnums.LAUNCHPAD_STATE.CANCELLED)) {
            _checkCanCancel();
        } else {
            require(
                status == uint256(IEnums.LAUNCHPAD_STATE.CANCELLED),
                "Launchpad: Sale must be cancelled"
            );
        }

        uint256 deposit = depositedAmount[msg.sender];
        require(deposit > 0, "Launchpad: User doesn't have deposits");
        depositedAmount[msg.sender] = 0;
        if (tokenPayment == address(0)) {
            payable(msg.sender).transfer(deposit);
        } else {
            IERC20(tokenPayment).transfer(msg.sender, deposit);
        }
        emit userRefunded(deposit, msg.sender);
    }

    function finishSale() external restricted nonReentrant {
        _checkCanFinish();
        status = uint256(IEnums.LAUNCHPAD_STATE.FINISHED);
        _ownerWithdraw();
        deployer.changeLaunchpadState(
            tokenSale,
            uint256(IEnums.LAUNCHPAD_STATE.FINISHED)
        );
        emit saleClosed(block.timestamp, totalDeposits);
    }

    function cancelSale() external restricted nonReentrant {
        _checkCanCancel();
        status = uint256(IEnums.LAUNCHPAD_STATE.CANCELLED);
        deployer.changeLaunchpadState(
            tokenSale,
            uint256(IEnums.LAUNCHPAD_STATE.CANCELLED)
        );
        IERC20(tokenSale).transfer(
            msg.sender,
            IERC20(tokenSale).balanceOf(address(this))
        );
        emit saleCanceled(block.timestamp, msg.sender);
    }

    function changeData(string memory _newData) external onlyOwner {
        URIData = _newData;
    }

    function enableWhitelist() external onlyOwner {
        require(usingWhitelist == false || (endOfWhitelistTime > 0 && block.timestamp > endOfWhitelistTime), "Whitelist mode is ongoing");
        usingWhitelist = true;
        endOfWhitelistTime = 0;
        deployer.changeActionChanged(address(this), usingWhitelist, endOfWhitelistTime);
    }

    function disableWhitelist(uint256 disableTime) external onlyOwner {
        require(usingWhitelist == true && (endOfWhitelistTime == 0 || block.timestamp < endOfWhitelistTime), "Whitelist mode is not ongoing");
        if (disableTime == 0) {
            usingWhitelist = false;
        } else {
            require(disableTime > block.timestamp);
            endOfWhitelistTime = disableTime;
        }
        deployer.changeActionChanged(address(this), usingWhitelist, endOfWhitelistTime);
    }

    function grantWhitelist(address[] calldata _users) external onlyOwner {
        address[] memory users = new address[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            if (!whitelist[_users[i]]) {
                whitelist[_users[i]] = true;
                users[i] = _users[i];
            }
        }
        deployer.changeWhitelistUsers(address(this), users, 0);
    }

    function revokeWhitelist(address[] calldata _users) external onlyOwner {
        address[] memory users = new address[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            if (whitelist[_users[i]]) {
                whitelist[_users[i]] = false;
                users[i] = _users[i];
            }
        }
        deployer.changeWhitelistUsers(address(this), users, 1);
    }

    function getContractInfo()
        external
        view
        returns (
            uint256[2] memory,
            uint256[3] memory,
            uint256[2] memory,
            uint256[2] memory,
            string memory,
            address,
            address,
            bool,
            uint256,
            uint256,
            bool,
            IEnums.LAUNCHPAD_TYPE
        )
    {
        return (
            [softCap, hardCap],
            [startTime, endTime, endSaleTime],
            [presaleRate, listingRate],
            [minBuyPerParticipant, maxBuyPerParticipant],
            URIData,
            tokenSale,
            tokenPayment,
            usingWhitelist,
            totalDeposits,
            status,
            refundWhenFinish,
            launchPadType
        );
    }

    function getContributorsList()
        external
        view
        returns (address[] memory list, uint256[] memory amounts)
    {
        list = new address[](contributorId);
        amounts = new uint256[](contributorId);

        for (uint256 i; i < contributorId; i++) {
            address userAddress = contributorsList[i];
            list[i] = userAddress;
            amounts[i] = depositedAmount[userAddress];
        }
    }

    function getTotalTokenSale() public view returns (uint256) {
        return
            (hardCap * presaleRate * 10**ERC20(tokenSale).decimals()) / 10**18;
    }

    function _ownerWithdraw() private {
        address DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
        uint256 balance;
        uint256 tokenSalefee;
        uint256 tokenPaymentfee;

        if (adminTokenSaleFee > 0) {
            tokenSalefee =
                ((
                    launchPadType == LAUNCHPAD_TYPE.NORMAL
                        ? totalRaised
                        : getTotalTokenSale()
                ) * adminTokenSaleFee) /
                10000;
        }
        if (tokenSalefee > 0) {
            IERC20(tokenSale).transfer(admin, tokenSalefee);
        }

        if (adminTokenPaymentFee > 0) {
            tokenPaymentfee = (totalDeposits * adminTokenPaymentFee) / 10000;
        }
        if (tokenPayment == address(0)) {
            balance = address(this).balance;
            payable(admin).transfer(tokenPaymentfee);
            payable(msg.sender).transfer(balance - tokenPaymentfee);
        } else {
            balance = IERC20(tokenPayment).balanceOf(address(this));
            IERC20(tokenPayment).transfer(admin, tokenPaymentfee);
            IERC20(tokenPayment).transfer(
                msg.sender,
                balance - tokenPaymentfee
            );
        }

        uint256 amountTokenSaleRemain = IERC20(tokenSale).balanceOf(
            address(this)
        );
        if (amountTokenSaleRemain > 0 && refundWhenFinish) {
            IERC20(tokenSale).transfer(msg.sender, amountTokenSaleRemain);
        }
        if (amountTokenSaleRemain > 0 && !refundWhenFinish) {
            IERC20(tokenSale).transfer(DEAD_ADDRESS, amountTokenSaleRemain);
        }
    }

    function _checkCanInvest(address _user) private view {
        // if (usingWhitelist && !whitelist[_user]) {
        //     require(
        //         endOfWhitelistTime > 0 && block.timestamp >= endOfWhitelistTime,
        //         "Launchpad: User can not invest"
        //     );
        // }
        require(
            usingWhitelist && (endOfWhitelistTime == 0 || block.timestamp < endOfWhitelistTime) && whitelist[_user] ||
            !usingWhitelist || usingWhitelist && endOfWhitelistTime > 0 && block.timestamp > endOfWhitelistTime,
            "Launchpad: User can not invest"
        );
    }

    function _checkCanFinish() private view {
        _checkCanClaimFund();
        if (
            launchPadType == LAUNCHPAD_TYPE.NORMAL &&
            block.timestamp < endSaleTime
        ) {
            require(
                totalNeedToRaised == 0,
                "Launchpad(Normal): All token sale need raised before end sale time"
            );
        }
        if (
            launchPadType == LAUNCHPAD_TYPE.FAIR &&
            block.timestamp < endSaleTime
        ) {
            require(
                ERC20(tokenSale).balanceOf(address(this)) <=
                    (getTotalTokenSale() * adminTokenSaleFee) / 10000,
                "Launchpad(Fair): All token sale need raised before end sale time"
            );
        }
    }

    function _checkCanClaimFund() private view {
        require(
            block.timestamp > endTime,
            "Launchpad: Finishing launchpad does not available now"
        );
        require(
            status == uint256(IEnums.LAUNCHPAD_STATE.OPENING),
            "Launchpad: Sale is already finished or cancelled"
        );
        if (launchPadType == LAUNCHPAD_TYPE.NORMAL) {
            require(
                totalDeposits >= softCap,
                "Launchpad(Normal): Soft cap not reached"
            );
        } else {
            require(
                totalDeposits >= hardCap,
                "Launchpad(Fair): Cap not reached"
            );
        }
    }

    function _checkCanCancel() private view {
        require(
            status == uint256(IEnums.LAUNCHPAD_STATE.OPENING),
            "Launchpad: Sale is already finished or cancelled"
        );
        if (launchPadType == IEnums.LAUNCHPAD_TYPE.NORMAL) {
            require(
                totalDeposits < softCap,
                "Launchpad(Normal): Soft cap reached"
            );
        } else {
            require(totalDeposits < hardCap, "Launchpad(Fair): Cap reached");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Launchpad.sol";

contract LaunchpadDeployer is IDeployer, Ownable {
    uint256 public deployCost = 0.001 ether;

    mapping(address => address) public launchpadByToken;
    mapping(IEnums.LAUNCHPAD_TYPE => uint256) public launchpadCount;
    mapping(IEnums.LAUNCHPAD_TYPE => mapping(uint256 => address))
        public launchpadById;
    mapping(IEnums.LAUNCHPAD_TYPE => mapping(address => uint256))
        public launchpadIdByAddress;
    mapping(IEnums.LAUNCHPAD_TYPE => mapping(address => address[]))
        public userLaunchpadInvested;
    mapping(IEnums.LAUNCHPAD_TYPE => mapping(address => address[]))
        public userLaunchpadCreated;
    mapping(IEnums.LAUNCHPAD_TYPE => mapping(address => mapping(address => bool))) isLaunchpadAdded;

    event launchpadDeployed(
        address launchpad,
        address deployer,
        address tokenSale,
        address tokenPayment,
        IEnums.LAUNCHPAD_TYPE launchPadType,
        string uriData,
        bool refundWhenFinish,
        uint256 startTime,
        uint256 endTime,
        uint256 claimTime,
        uint256 adminTokenSaleFee
    );

    event launchpadDeployedParameter(
        address launchpad,
        uint256 softcap,
        uint256 hardcap,
        uint256 presaleRate,
        uint256 listingRate,
        uint256 minBuyPerParticipant,
        uint256 maxBuyPerParticipant
    );

    event launchpadStateChanged(address launchpad, uint256 state);

    event launchpadRaisedChanged(address launchpad, uint256 newRaisedAmount, uint256 newNeedToRaised);

    event launchpadActionChanged(address launchpad, bool usingWhitelist, uint256 endOfWhitelistTime);

    event launchpadWhitelistUsersChanged(address launchpad, address[] users, uint256 action);

    function createLaunchpad(
        uint256[2] memory _caps,
        uint256[3] memory _times,
        uint256[2] memory _rates,
        uint256[2] memory _limits,
        uint256[2] memory _adminFees,
        address[2] memory _tokens,
        string memory _URIData,
        bool _refundWhenFinish,
        IEnums.LAUNCHPAD_TYPE _launchpadType
    ) public payable {
        _checkCanCreateLaunch(_tokens[0]);
        if (_launchpadType == IEnums.LAUNCHPAD_TYPE.FAIR) {
            require(
                _caps[0] == 0 && _limits[0] == 0 && _limits[1] == 0,
                "Invalid create launch input"
            );
        }
        LaunchPad newLaunchpad = new LaunchPad(
            _caps,
            _times,
            _rates,
            _limits,
            _adminFees,
            _tokens,
            _URIData,
            owner(),
            _refundWhenFinish,
            _launchpadType
        );
        _sendTokenToLaunchContract(
            _rates[0],
            _caps[1],
            _tokens[0],
            _adminFees[0],
            address(newLaunchpad)
        );
        _updateLaunchpadData(
            _launchpadType,
            launchpadCount[_launchpadType],
            address(newLaunchpad),
            _tokens[0]
        );
        newLaunchpad.transferOwnership(msg.sender);
        payable(owner()).transfer(msg.value);
        emit launchpadDeployed(
            address(newLaunchpad),
            msg.sender,
            _tokens[0],
            _tokens[1],
            _launchpadType,
            _URIData,
            _refundWhenFinish,
            _times[0],
            _times[1],
            _times[2],
            _adminFees[0]
        );
        emit launchpadDeployedParameter(
            address(newLaunchpad),
            _caps[0],
            _caps[1],
            _rates[0],
            _rates[1],
            _limits[0],
            _limits[1]
        );
    }

    function getDeployedLaunchpads(
        uint256 startIndex,
        uint256 endIndex,
        IEnums.LAUNCHPAD_TYPE _launchpadType
    ) public view returns (address[] memory) {
        if (endIndex >= launchpadCount[_launchpadType]) {
            endIndex = launchpadCount[_launchpadType] - 1;
        }

        uint256 arrayLength = endIndex - startIndex + 1;
        uint256 currentIndex;
        address[] memory launchpadAddress = new address[](arrayLength);

        for (uint256 i = startIndex; i <= endIndex; i++) {
            launchpadAddress[currentIndex] = launchpadById[_launchpadType][
                startIndex + i
            ];
            currentIndex++;
        }

        return launchpadAddress;
    }

    function setDeployPrice(uint256 _price) external onlyOwner {
        deployCost = _price;
    }

    function addToUserLaunchpad(
        address _user,
        address _token,
        IEnums.LAUNCHPAD_TYPE _launchpadType
    ) external override {
        require(
            launchpadByToken[_token] == msg.sender,
            "Only launchpads can do add"
        );
        if (!isLaunchpadAdded[_launchpadType][_user][msg.sender]) {
            userLaunchpadInvested[_launchpadType][_user].push(msg.sender);
            isLaunchpadAdded[_launchpadType][_user][msg.sender] = true;
        }
    }

    function changeLaunchpadState(address _token, uint256 _newState)
        external
        override
    {
        require(
            launchpadByToken[_token] == msg.sender,
            "Only launchpads can remove"
        );
        emit launchpadStateChanged(launchpadByToken[_token], _newState);
        launchpadByToken[_token] = address(0);
    }

    function changeActionChanged(address launchpad, bool usingWhitelist, uint256 endOfWhitelistTime) external override {
        emit launchpadActionChanged(launchpad, usingWhitelist, endOfWhitelistTime);
    }

    function changeWhitelistUsers(address launchpad, address[] memory users, uint256 action) external override {
        emit launchpadWhitelistUsersChanged(launchpad, users, action);
    }

    function launchpadRaisedAmountChangedReport(
        address _token,
        uint256 _currentRaisedAmount,
        uint256 _currentNeedToRaised
    ) external override {
        require(
            launchpadByToken[_token] == msg.sender,
            "Only launchpads can report"
        );
        emit launchpadRaisedChanged(
            launchpadByToken[_token],
            _currentRaisedAmount,
            _currentNeedToRaised
        );
    }

    function getAllLaunchpads()
        external
        view
        returns (address[] memory, address[] memory)
    {
        uint256 numberOfNormalLaunchpad = launchpadCount[
            IEnums.LAUNCHPAD_TYPE.NORMAL
        ];
        uint256 numberOfFairLaunchpad = launchpadCount[
            IEnums.LAUNCHPAD_TYPE.FAIR
        ];
        address[] memory allNormalLaunchpads = new address[](
            numberOfNormalLaunchpad
        );
        address[] memory allFairLaunchpads = new address[](
            numberOfFairLaunchpad
        );
        uint256 counter = numberOfNormalLaunchpad > numberOfFairLaunchpad
            ? numberOfNormalLaunchpad
            : numberOfFairLaunchpad;
        for (uint256 i = 0; i < counter; i++) {
            if (i < numberOfNormalLaunchpad) {
                allNormalLaunchpads[i] = launchpadById[
                    IEnums.LAUNCHPAD_TYPE.NORMAL
                ][i];
            }
            if (i < numberOfFairLaunchpad) {
                allFairLaunchpads[i] = launchpadById[
                    IEnums.LAUNCHPAD_TYPE.FAIR
                ][i];
            }
        }
        return (allNormalLaunchpads, allFairLaunchpads);
    }

    function getUserContributions(
        address _user,
        IEnums.LAUNCHPAD_TYPE _launchpadType
    )
        external
        view
        returns (uint256[] memory ids, uint256[] memory contributions)
    {
        uint256 count = userLaunchpadInvested[_launchpadType][_user].length;
        ids = new uint256[](count);
        contributions = new uint256[](count);

        for (uint256 i; i < count; i++) {
            address launchpadaddress = userLaunchpadInvested[_launchpadType][
                _user
            ][i];
            ids[i] = launchpadIdByAddress[_launchpadType][launchpadaddress];
            contributions[i] = LaunchPad(launchpadaddress).depositedAmount(
                _user
            );
        }
    }

    function _checkCanCreateLaunch(address _token) private {
        require(msg.value >= deployCost, "Not enough BNB to deploy");
        require(
            launchpadByToken[_token] == address(0),
            "Launchpad already created"
        );
    }

    function _sendTokenToLaunchContract(
        uint256 _presaleRate,
        uint256 _cap,
        address _tokenSale,
        uint256 _adminTokenSaleFee,
        address _launchpad
    ) private {
        uint256 tokensToDistribute = (_presaleRate *
            _cap *
            10**ERC20(_tokenSale).decimals()) / 10**18;
        if (_adminTokenSaleFee > 0) {
            tokensToDistribute +=
                (tokensToDistribute * _adminTokenSaleFee) /
                10000;
        }
        ERC20(_tokenSale).transferFrom(
            msg.sender,
            _launchpad,
            tokensToDistribute
        );
    }

    function _updateLaunchpadData(
        IEnums.LAUNCHPAD_TYPE _launchpadType,
        uint256 _launchpadCount,
        address _launchpad,
        address _token
    ) private {
        launchpadByToken[_token] = _launchpad;
        launchpadById[_launchpadType][_launchpadCount] = _launchpad;
        launchpadIdByAddress[_launchpadType][_launchpad] = _launchpadCount;
        launchpadCount[_launchpadType]++;
        userLaunchpadCreated[_launchpadType][msg.sender].push(_launchpad);
    }
}