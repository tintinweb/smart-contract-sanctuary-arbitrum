/**
 *Submitted for verification at Arbiscan.io on 2023-09-02
*/

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File:@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol;

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;


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
        }
        _balances[to] += amount;

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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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


// File: contracts/interface/IWETH.sol


pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts/libraries/TransferHelper.sol



pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

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

//File:contracts/struct/User.sol
pragma solidity ^0.8.0;

    struct User{
        uint PID;
        address account;
        string username;
        string information;
        uint joinTime;
    }
// File:contracts/interface/IFirePassport.sol
pragma solidity ^0.8.0;
interface IFirePassport {
    function usernameExists(string memory username) external returns(bool);
    function getUserCount() external view  returns(uint);
    function hasPID(address user) external view returns(bool);
    function getUserInfo(address user) external view returns(User memory);
    }

// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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
 * ```
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
//File:./lib/safeMath.sol

pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IFireSeedCoupon {
    function _mintExternal(address _to, uint256 _amount) external;
}

contract PrivateExchangePoolOgV3 is Ownable,Pausable ,ReentrancyGuard{

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

  uint256 constant private invitationLevel = 5;
    struct assignAndRate {
        address assign;
        uint256 rate;
    }
    EnumerableSet.AddressSet private adminsLevelTwo;
    EnumerableSet.AddressSet private adminsLevelThree;
    EnumerableSet.AddressSet private adminsLevelFour;
    EnumerableSet.AddressSet private adminsLevelFive;
    EnumerableSet.AddressSet private activateAccount;

    ERC20 public flm;
	ERC20 public fdtOg;
    address public FireSeedCoupon;
    uint256  maxUint256 = 2**256 - 1;
    uint256 public FSC;
    uint256 public userFlmRewardRate;
    bool public pidStatusForAdmin;
    bool public pidStatusForUser;
    bool public initRate;
    bool public initTeamRate;
    bool public initFlmRate;
	address public weth;
    address public receiveRemainingTeamRewards;
    address public firePassport_;
    uint256 public registerId;
	uint256 public salePrice;
    uint256 public maxTwo;
    uint256 public maxThree;
    uint256 public maxFour;
    uint256 public maxFive;
    uint256 public activateAccountUsedAmount;
    uint256 public userBuyMax;
    uint256[] public inviteRate;
    uint256[] public teamRate;
    uint256[] public flmRate;
    uint256 public buyId;
    uint256 public totalDonate;
    uint256[] public validNumbers =
    [
        200000000000000000,
        400000000000000000,
        600000000000000000,
        800000000000000000,
        1000000000000000000,
        1200000000000000000,
        1400000000000000000,
        1600000000000000000,
        1800000000000000000,
        2000000000000000000
    ];
    assignAndRate[] public assignAndRates;
	mapping(address => uint256) public userTotalBuy;
    mapping(address => bool) public isRecommender;
    mapping(address => address) public recommender;
    mapping(address => address[]) public setAdminLevelTwo_;
    mapping(address => address[]) public setAdminLevelThree_;
    mapping(address => address[]) public setAdminLevelFour_;
    mapping(address => address[]) public setAdminLevelFive_;
    mapping(address => bool) public isNotRegister;
    mapping(address => uint256) public activeInviteAmount;
    mapping(address => uint256) public activeUsedAmount;
    mapping(address => mapping(uint256 => address)) public userTeamReward;
    mapping(uint256 => uint256) public adminFlmReward;
    mapping(address => address) public userTeam;
    mapping(address =>mapping(address => bool)) public blackList;
	AggregatorV3Interface internal priceFeed;
    event allFlmRate(
        uint256 flmRate4,
        uint256 flmRate3,
        uint256 flmRate2,
        uint256 flmRate1,
        uint256 flmRate0,
        uint256 adminFlmRate4,
        uint256 adminFlmRate3,
        uint256 adminFlmRate2,
        uint256 adminFlmRate1,
        uint256 adminFlmRate0,
        address user
    );
    event allInvite(
        address recommender1,
        address recommender2,
        address recommender3,
        address recommender4,
        address recommender5,
        uint256 rate1,
        uint256 rate2,
        uint256 rate3,
        uint256 rate4,
        uint256 rate5,
        address addr
    );
    event allRecord(
        uint256 no,
        uint256 fscAmount,
        uint256 salePrice,
        address recommender,
        address addr,
        uint256 ethAmount,
        uint256 usdtAmount,
        uint256 fdtAmount,
        uint256 flmAmount
        );
        event allTeamRate(
            address admin0,
            address admin1,
            address admin2,
            address admin3,
            address admin4,
            uint256 adminRate0,
            uint256 adminRate1,
            uint256 adminRate2,
            uint256 adminRate3,
            uint256 adminRate4,
            address addr
        );
        event SetActive(
            address _seter,
            address _user
        );
    event allRegister(uint256 id,address recommenders, address _user);
    event blackUser(address operator, address user);
    modifier onlyAdminTwo() {
        require(checkAddrForAdminLevelTwo(msg.sender));
        _;
    }
    modifier onlyAdminThree() {
        require(checkAddrForAdminLevelThree(msg.sender));
        _;
    }
    modifier onlyAdminFour() {
        require(checkAddrForAdminLevelFour(msg.sender));
        _;
    }
    modifier onlyAdminFive() {
        require(checkAddrForAdminLevelFive(msg.sender));
        _;
    }
	/**
		* NetWork: Goerli
		* Aggregator: ETH/USD
		* Address:0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        * Arb goerli:0x62CAe0FA2da220f43a51F86Db2EDb36DcA9A5A08
        * Arb One:0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
        * ETH Address :0x5D0C84105D44919Dee994d729f74f8EcD05c30fB
        * mumbai test net address: 0x0715A7794a1dc8e42615F059dD6e406A6594651A
	*/
	constructor(ERC20 _fdtOg,ERC20 _flm,address _fireSeedCoupon,  address _weth, address _firePassport) {
		priceFeed = AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);//arb one 
		// priceFeed = AggregatorV3Interface(0x62CAe0FA2da220f43a51F86Db2EDb36DcA9A5A08);//arb goerli
		// priceFeed = AggregatorV3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A);//mumbai
		fdtOg = _fdtOg;
        flm = _flm;
		weth = _weth;
		salePrice = 11;
        maxTwo = 50;
        maxThree = 50;
        maxFour = 50;
        maxFive = 50;
        activateAccountUsedAmount = 50;
        userBuyMax = 2000000000000000000;
        firePassport_ = _firePassport;
        registerId =1;
        receiveRemainingTeamRewards = msg.sender;
        FireSeedCoupon = _fireSeedCoupon;
        FSC = 1;
        userFlmRewardRate = 10;

	}
    function setFireSeedCoupon(address _addr) public onlyOwner {
        FireSeedCoupon = _addr;
    }
    function setFSC(uint256 _fsc)public onlyOwner {
        FSC = _fsc;
    }
    function setReceiveRemainingTeamRewards(address _addr) public onlyOwner{
        receiveRemainingTeamRewards = _addr;
    }
    function setActivateAccountUsedAmount(uint256 _amount) public onlyOwner {
        activateAccountUsedAmount = _amount;
    }
    function isValidNumber(uint256 number) private view returns (bool) {
        for (uint i = 0; i < validNumbers.length; i++) {
            if (validNumbers[i] == number) {
                return true;
            }
        }
        return false;
    }
	//onlyOwner
    function setWeth(address _weth) public onlyOwner {
        weth = _weth;
    }
    //set isNot need Pid;
    function setPidStatusForAdmin() public onlyOwner{
        pidStatusForAdmin = !pidStatusForAdmin;
    }
    function setPidStatusForUser() public onlyOwner {
        pidStatusForUser = !pidStatusForUser;
    }
    function setUserBuyMax(uint256 _amount) public onlyOwner{
        userBuyMax = _amount;
    }
    function setFlmAddress(ERC20 _flm) public onlyOwner {
        flm = _flm;
    }
	function setFDTAddress(ERC20 _fdtOg) public onlyOwner {
		fdtOg = _fdtOg;
	}
	function setSalePrice(uint256 _salePrice) public onlyOwner {
		salePrice = _salePrice;
	}
    function setAdminForTwo(uint256 _max) public onlyOwner {
        if(_max == 0) {
        maxTwo = maxUint256;
        return;
        }
        maxTwo = _max;
    }
    function setAdminForThree(uint256 _max) public onlyOwner {
        if(_max == 0) {
        maxThree = maxUint256;
        return;
        }
        maxThree = _max;
    }
    function setAdminForFour(uint256 _max) public onlyOwner {
        if(_max == 0) {
        maxFour = maxUint256;
        return;
        }
        maxFour = _max;
    }
    function setAdminForFive(uint256 _max) public onlyOwner {
        if(_max ==  0) {
            maxFive = maxUint256;
            return;
        }
        maxFive = _max;
    }
 
    function checkAddrForActivateAccount(address _user) public view returns(bool) {
        return activateAccount.contains(_user);
    }
    function checkAddrForAdminLevelTwo(address _user) public view returns(bool) {
        return adminsLevelTwo.contains(_user);
    }
    function checkAddrForAdminLevelThree(address _user) public view returns(bool){
        return adminsLevelThree.contains(_user);
    }
    function checkAddrForAdminLevelFour(address _user) public view returns(bool){
        return adminsLevelFour.contains(_user);
    }
    function checkAddrForAdminLevelFive(address _user) public view returns(bool){
        return adminsLevelFive.contains(_user);
    }
    function setBlackList(address _user) public onlyAdminTwo{
        require(msg.sender == recommender[_user] || msg.sender == recommender[recommender[_user]] ||msg.sender == recommender[recommender[recommender[_user]]] );
        blackList[msg.sender][_user] = !blackList[msg.sender][_user];
        emit blackUser(msg.sender,_user );
    }
    function inviteFunc(address _addr , address _admin) internal{
        if (recommender[_addr] == address(0) &&  recommender[_addr] != _admin && !isRecommender[_addr] ) {
             recommender[_addr] = _admin;
             isRecommender[_addr] = true;
             }else{
            revert();
             }
    }
    function setAdminLevelTwo(address[] memory _addr) public onlyOwner{
        for(uint i = 0; i < _addr.length;i++){
            if(pidStatusForAdmin){
                require(IFirePassport(firePassport_).hasPID(_addr[i]));
            }
            require(msg.sender != _addr[i]);
            require(!isNotRegister[_addr[i]]);
            require(!checkAddrForAdminLevelTwo(_addr[i]));
            inviteFunc(_addr[i],msg.sender);
            adminsLevelTwo.add(_addr[i]);
            setAdminLevelTwo_[msg.sender].push(_addr[i]);
            emit allRegister(0, msg.sender, _addr[i]);
        }
    }

    function setAdminLevelThree(address[] memory _addr) public onlyAdminTwo {
        require(setAdminLevelThree_[msg.sender].length < getMax(msg.sender) && _addr.length < getMax(msg.sender));
        for(uint256 i = 0; i < _addr.length; i++){
            if(pidStatusForAdmin){
                require(IFirePassport(firePassport_).hasPID(_addr[i]));
            }
            require(msg.sender != _addr[i]);
            require(!isNotRegister[_addr[i]]);
            require(!checkAddrForAdminLevelThree(_addr[i]));
            inviteFunc(_addr[i],msg.sender);
            adminsLevelThree.add(_addr[i]);
            setAdminLevelThree_[msg.sender].push(_addr[i]);
            emit allRegister(0, msg.sender, _addr[i]);
            
        }
    }
      function setAdminLevelFour(address[] memory _addr) public onlyAdminThree{
        require(setAdminLevelFour_[msg.sender].length < getMax(msg.sender) && _addr.length < getMax(msg.sender));
        for(uint i=0;i<_addr.length;i++){
            if(pidStatusForUser){
                require(IFirePassport(firePassport_).hasPID(_addr[i]));
            }
            require(msg.sender != _addr[i]);
            require(!isNotRegister[_addr[i]]);    
            require(!checkAddrForAdminLevelFour(_addr[i]));
            inviteFunc(_addr[i],msg.sender);
            adminsLevelFour.add(_addr[i]);
           setAdminLevelFour_[msg.sender].push(_addr[i]);
            emit allRegister(0, msg.sender, _addr[i]);

        }
    }
    function setAdminLevelFive(address[] memory _addr) public onlyAdminFour {
        require(setAdminLevelFive_[msg.sender].length < getMax(msg.sender) && _addr.length < getMax(msg.sender));
        for(uint i=0;i<_addr.length;i++){
            if(pidStatusForUser){
                require(IFirePassport(firePassport_).hasPID(_addr[i]));
            }
            require(msg.sender != _addr[i]);
            require(!isNotRegister[_addr[i]]);    
            require(!checkAddrForAdminLevelFive(_addr[i]));
            inviteFunc(_addr[i],msg.sender);
            adminsLevelFive.add(_addr[i]);
            setAdminLevelFive_[msg.sender].push(_addr[i]);
            emit allRegister(0, msg.sender, _addr[i]);
        }
    }

    function removeAdminLevelTwo(address _addr) public onlyOwner{
        adminsLevelTwo.remove(_addr);
        for(uint256 i = 0 ; i < setAdminLevelTwo_[msg.sender].length; i ++) {
            if(_addr == setAdminLevelTwo_[msg.sender][i]){
                setAdminLevelTwo_[msg.sender][i] = setAdminLevelTwo_[msg.sender][setAdminLevelTwo_[msg.sender].length - 1];
                setAdminLevelTwo_[msg.sender].pop();
                return;
            }
        }
    }
    function removeAdminLevelThree(address _addr) public onlyAdminTwo {
        adminsLevelThree.remove(_addr);
          for(uint256 i = 0 ; i < setAdminLevelThree_[msg.sender].length; i ++) {
            if(_addr == setAdminLevelTwo_[msg.sender][i]){
                setAdminLevelThree_[msg.sender][i] = setAdminLevelThree_[msg.sender][setAdminLevelThree_[msg.sender].length - 1];
                setAdminLevelThree_[msg.sender].pop();
                return;
            }
        }
    }
    function removeAdminLevelFour(address _addr) public onlyAdminThree{
        adminsLevelFour.remove(_addr);
          for(uint256 i = 0 ; i < setAdminLevelFour_[msg.sender].length; i ++) {
            if(_addr == setAdminLevelFour_[msg.sender][i]){
                setAdminLevelFour_[msg.sender][i] = setAdminLevelFour_[msg.sender][setAdminLevelFour_[msg.sender].length - 1];
                setAdminLevelFour_[msg.sender].pop();
                return;
            }
        }
    }
    function removeAdminLevelFive(address _addr) public onlyAdminFour{
        adminsLevelFive.remove(_addr);
               for(uint256 i = 0 ; i < setAdminLevelFour_[msg.sender].length; i ++) {
            if(_addr == setAdminLevelFour_[msg.sender][i]){
                setAdminLevelFour_[msg.sender][i] = setAdminLevelFour_[msg.sender][setAdminLevelFour_[msg.sender].length - 1];
                setAdminLevelFour_[msg.sender].pop();
                return;
            }
        }
           
    }
    
    function getMax(address _user) internal view returns(uint256) {
        if(checkAddrForAdminLevelTwo(_user)){
            return maxTwo;
        }else if(checkAddrForAdminLevelThree(_user)) {
            return maxThree;
        }else if(checkAddrForAdminLevelFour(_user)){
            return maxFour;
        }else if(checkAddrForAdminLevelFive(_user)){
            return maxFive;
        }
        return 0;
    }
  function setActivateAccountForL2(address[] memory _user)public  onlyAdminTwo {
        for(uint256 i = 0 ; i < _user.length ; i++){
            require(!checkAddrForActivateAccount(_user[i]) && isNotRegister[_user[i]] == true);
            activateAccount.add(_user[i]);
            emit SetActive(msg.sender, _user[i]);
        }
    }
    function setActivateAccountForL5(address[] memory  _user) public onlyAdminFive{
    require(activeInviteAmount[msg.sender] <= getMax(msg.sender) && _user.length < getMax(msg.sender));
        for(uint256 i =0 ; i < _user.length ;i++) {
            require(!isNotRegister[_user[i]]);
            require(!checkAddrForActivateAccount(_user[i]));
            activateAccount.add(_user[i]);
            inviteFunc(_user[i],msg.sender);
            activeInviteAmount[msg.sender] = activeInviteAmount[msg.sender].add(1);
            userTeamReward[_user[i]][0] = msg.sender;
            userTeamReward[_user[i]][1] = recommender[msg.sender];
            userTeamReward[_user[i]][2] = recommender[recommender[msg.sender]];
            userTeamReward[_user[i]][3] = recommender[recommender[recommender[msg.sender]]];
            userTeamReward[_user[i]][4] = recommender[recommender[recommender[recommender[msg.sender]]]];
            emit SetActive(msg.sender, _user[i]);

        }
    }
  

    function addAssignAddressAndRatio(address[] memory _addr, uint256[] memory _rate) public onlyOwner{
        require(initRate);
        for(uint i = 0 ; i < _addr.length; i++) {
             if(assignAndRates.length > 0 ) {
               require(checkRepeat(_addr[i])) ;
        }
            assignAndRate memory ar = assignAndRate({assign:_addr[i],rate:_rate[i]});
            assignAndRates.push(ar);
        }
    }

    function checkRepeat(address _addr) internal view returns(bool){
        for(uint256 i = 0 ; i < assignAndRates.length ; i ++) {
            if(_addr == assignAndRates[i].assign) {
                return false;
            }
        }
        return true;
    }
    function removeAssiginAddressAndRatio(address[] memory _addr) public onlyOwner{
        for(uint256 j = 0 ; j < _addr.length ;j ++ ) {
        for(uint256 i = 0; i < assignAndRates.length ; i++){
            if(assignAndRates[i].assign == _addr[j]) {
                assignAndRates[i] = assignAndRates[assignAndRates.length - 1];
                assignAndRates.pop();
                return;
            }
        }
    }
    revert();
}

    function setAssignAddressAndRatio(uint256 _id, address _addr,uint256 _rate) public onlyOwner{
        assignAndRates[_id] = assignAndRate({
            assign: _addr,
            rate: _rate
        });

    }
    function addFlmRate(uint256[] memory _rate) public onlyOwner 
    {
        require(!initFlmRate);
        require(_rate.length == 5 );
        for(uint256 i = 0 ;i < _rate.length; i++){
            flmRate.push(_rate[i]);
        }
        initFlmRate = true;

    }
    function setFlmRate(uint256 _id , uint256 _rate) public onlyOwner {
        flmRate[_id] = _rate;
    }
    function setUserFlmRewards(uint256 _rate) public onlyOwner {
        userFlmRewardRate = _rate;
    }
    function setAdminFlmReward(uint256[] memory _rate) public onlyOwner {
        for(uint256 i = 0 ; i < 5 ; i++) {
        adminFlmReward[i] = _rate[i];

        }
    }
    function addTeamRate(uint256[] memory _rate) public onlyOwner{
        require(!initTeamRate);
        require(_rate.length ==5);
        for(uint256 i = 0 ;i < _rate.length; i++){
            teamRate.push(_rate[i]);
        }
        initTeamRate = true;
    }
   function setTeamRate(uint256 _id, uint256 _rate) public onlyOwner {
       require(_id < teamRate.length);
       teamRate[_id] = _rate;
   }
    function addInviteRate(uint256[] memory _rate) public onlyOwner{
        require(!initRate);
        require(_rate.length == 5 || inviteRate.length < 5 );
        for(uint256 i = 0; i < _rate.length; i++) {
            inviteRate.push(_rate[i]);
        }
        initRate = true;

    }
    function setInviteRate(uint256 _id , uint256 _rate) public onlyOwner{
        require(_id < inviteRate.length, 'input error');
        inviteRate[_id] = _rate;
    }

    function getRate() public view returns(uint256){
        uint256 total;
        uint256 _inviteRate;
        uint256 _teamRate;
        for(uint i = 0; i<assignAndRates.length; i++){
            total += assignAndRates[i].rate;
        }
        for(uint i = 0 ; i< inviteRate.length ; i ++ ){
            _inviteRate += inviteRate[i];
        }
        for(uint i = 0; i < teamRate.length; i++){
            _teamRate+= teamRate[i];
        }
        return total + _inviteRate + _teamRate;
    }
  
    function Claim(address tokenAddress, uint256 tokens)
    public
    onlyOwner
    returns (bool success)
    {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }
    function register(address _activationAddress) public nonReentrant whenNotPaused {
        require(checkAddrForActivateAccount(_activationAddress));
        require(!checkAddrForAdminLevelFive(msg.sender) &&
                !checkAddrForAdminLevelFour(msg.sender) &&
                !checkAddrForAdminLevelThree(msg.sender) &&
                !checkAddrForAdminLevelTwo(msg.sender));
        require(activeUsedAmount[_activationAddress] <= activateAccountUsedAmount);
        if(checkAddrForActivateAccount(msg.sender) == true && isNotRegister[msg.sender] == false) {
            isNotRegister[msg.sender] = true;
            emit allRegister(registerId,recommender[msg.sender],msg.sender);
            registerId++;
            return;
        }
        require(!isNotRegister[msg.sender] && !isRecommender[msg.sender] );
        inviteFunc(msg.sender, _activationAddress);
        userTeam[msg.sender] =_activationAddress;
        for(uint256 i = 0 ; i < 5 ; i++){
        userTeamReward[msg.sender][i] = userTeamReward[_activationAddress][i];
        }
        isNotRegister[msg.sender] = true;
        activeUsedAmount[_activationAddress] = activeUsedAmount[_activationAddress].add(1);
        emit allRegister(registerId,_activationAddress,msg.sender);
        registerId++;

    }
    function donate(uint256 fee) external payable whenNotPaused  nonReentrant{
        require(isNotRegister[msg.sender]);
        require(getRate() == 100);
        if (pidStatusForUser) {
            require(IFirePassport(firePassport_).hasPID(msg.sender));
        }else if(!checkAddrForActivateAccount(msg.sender)){
            activateAccount.add(msg.sender);
        }
        address[invitationLevel] memory invite;
        uint256 fdtAmount = fee.mul(getLatesPrice()).div(10**5 * salePrice);
        uint256 usdtAmount = fee.mul(getLatesPrice()).div(10**8);
        uint256 flmAmount = fdtAmount.mul(userFlmRewardRate).div(100);
        for(uint i = 1 ; i < invitationLevel; i++){
        invite[0] = recommender[msg.sender];
        invite[i] = recommender[invite[i - 1]];
        }
        require(fdtAmount <= getBalanceOfFDTOG());
        require(userTotalBuy[msg.sender].add(fee) <= userBuyMax);
        require(isValidNumber(fee));
                require(msg.value == fee);
                IWETH(weth).deposit{value: fee}();
                for (uint256 i = 0; i < assignAndRates.length; i++) {
                    IWETH(weth).transfer(assignAndRates[i].assign, fee.mul(assignAndRates[i].rate).div(100));
                    }
                    for(uint i = 0; i< invitationLevel;i++){
                    IWETH(weth).transfer(invite[i], fee.mul(inviteRate[i]).div(100));
                    flm.transfer(invite[i],fdtAmount.mul(flmRate[i]).div(100));
                    }
                    if(
                        blackList[userTeamReward[msg.sender][3]][userTeamReward[msg.sender][2]] &&
                        blackList[userTeamReward[msg.sender][3]][userTeamReward[msg.sender][1]] && 
                        blackList[userTeamReward[msg.sender][3]][userTeamReward[msg.sender][0]]){
                        IWETH(weth).transfer(receiveRemainingTeamRewards, fee.mul(teamRate[0].add(teamRate[1]).add(teamRate[2])).div(100));
                    }else if(blackList[userTeamReward[msg.sender][3]][userTeamReward[msg.sender][1]] ){
                        IWETH(weth).transfer(userTeamReward[msg.sender][2], fee.mul(teamRate[2]).div(100));
                        IWETH(weth).transfer([msg.sender][0], fee.mul(teamRate[0]).div(100));
                        IWETH(weth).transfer(receiveRemainingTeamRewards, fee.mul(teamRate[1]).div(100));
                        flm.transfer(userTeamReward[msg.sender][0], fdtAmount.mul(adminFlmReward[0]).div(100));
                        flm.transfer(userTeamReward[msg.sender][2], fdtAmount.mul(adminFlmReward[2]).div(100));

                    }else if(blackList[userTeamReward[msg.sender][3]][userTeamReward[msg.sender][0]]){
                        IWETH(weth).transfer(receiveRemainingTeamRewards, fee.mul(teamRate[0]).div(100));
                        IWETH(weth).transfer(userTeamReward[msg.sender][1], fee.mul(teamRate[1]).div(100));
                        IWETH(weth).transfer(userTeamReward[msg.sender][2], fee.mul(teamRate[2]).div(100));
                        flm.transfer(userTeamReward[msg.sender][1], fdtAmount.mul(adminFlmReward[1]).div(100));
                        flm.transfer(userTeamReward[msg.sender][2], fdtAmount.mul(adminFlmReward[2]).div(100));
                    }else if(blackList[userTeamReward[msg.sender][3]][userTeamReward[msg.sender][2]]){
                        IWETH(weth).transfer(receiveRemainingTeamRewards, fee.mul(teamRate[2]).div(100));
                        IWETH(weth).transfer(userTeamReward[msg.sender][1], fee.mul(teamRate[1]).div(100));
                        IWETH(weth).transfer(userTeamReward[msg.sender][0], fee.mul(teamRate[0]).div(100));
                        flm.transfer(userTeamReward[msg.sender][1], fdtAmount.mul(adminFlmReward[1]).div(100));
                        flm.transfer(userTeamReward[msg.sender][0], fdtAmount.mul(adminFlmReward[0]).div(100));
                    }
                    else{
                        for(uint i = 0 ; i < 3 ;i ++){
                        IWETH(weth).transfer(userTeamReward[msg.sender][i], fee.mul(teamRate[i]).div(100));
                        flm.transfer(userTeamReward[msg.sender][i], fdtAmount.mul(adminFlmReward[i]).div(100));
                        }
                    }
                IFireSeedCoupon(FireSeedCoupon)._mintExternal(recommender[msg.sender],FSC*10**18);
                IWETH(weth).transfer(userTeamReward[msg.sender][3], fee.mul(teamRate[3]).div(100));
                IWETH(weth).transfer(userTeamReward[msg.sender][4], fee.mul(teamRate[4]).div(100));
                flm.transfer(userTeamReward[msg.sender][3], fdtAmount.mul(adminFlmReward[3]).div(100));
                flm.transfer(userTeamReward[msg.sender][4], fdtAmount.mul(adminFlmReward[4]).div(100));
                flm.transfer(msg.sender, flmAmount);
        fdtOg.transfer(msg.sender, fdtAmount);
        userTotalBuy[msg.sender] = userTotalBuy[msg.sender].add(fee);
        totalDonate = totalDonate.add(fee);
            emit allRecord(
            buyId,
            FSC,
            salePrice,
            recommender[msg.sender],
            msg.sender,
            fee,
            usdtAmount,
            fdtAmount,
            flmAmount
            );
            emit allFlmRate(
            flmRate[4],
            flmRate[3],
            flmRate[2],
            flmRate[1],
            flmRate[0],
            adminFlmReward[4],
            adminFlmReward[3],
            adminFlmReward[2],
            adminFlmReward[1],
            adminFlmReward[0],
            msg.sender
            );
            emit allInvite(
            invite[4],
            invite[3],
            invite[2],
            invite[1],
            invite[0],
            inviteRate[4],
            inviteRate[3],
            inviteRate[2],
            inviteRate[1],
            inviteRate[0],
            msg.sender
            );
            emit allTeamRate(
                userTeamReward[msg.sender][4],
                userTeamReward[msg.sender][3],
                userTeamReward[msg.sender][2],
                userTeamReward[msg.sender][1],
                userTeamReward[msg.sender][0],
                teamRate[4],
                teamRate[3],
                teamRate[2],
                teamRate[1],
                teamRate[0],
                msg.sender
            );
        buyId++;
    }

	function getLatesPrice() public view returns (uint256) {
		(
			,
			int price,
			,
			,
			
		) = priceFeed.latestRoundData();
		return uint256(price);
	}
    function getBalanceOfFlm() public view returns(uint256){
        return flm.balanceOf(address(this));
    }
	function getBalanceOfFDTOG() public view returns(uint256) {
		return fdtOg.balanceOf(address(this));
	}
    function getAssignAndRateslength() public view returns(uint256) {
        return assignAndRates.length;
    }
    function getAdminsLevelOneLength( address _user) public view returns( uint256 ) {
        return setAdminLevelTwo_[_user].length;
    }
    function getAdminsLevelTwoLength(address _adminTwo) public view returns(uint256 ) {
        return setAdminLevelThree_[_adminTwo].length;
    }
     function getAdminsLevelThreeLength(address _adminThree) public view returns(uint256) {
        return setAdminLevelThree_[_adminThree].length;
    }
    function getAdminsLevelFourLength(address _adminFour) public view returns(uint256) {
        return setAdminLevelFour_[_adminFour].length;
    }
      function getAdminsLevelFiveLength(address _adminFive) public view returns(uint256) {
        return setAdminLevelFive_[_adminFive].length;
    }
    
    function getfdtOgAmount(uint256 fee) public view returns(uint256) {
	return (fee*getLatesPrice()/10**5)/salePrice;
    }
    function getValue() public view returns(uint256) {
        return getBalanceOfFDTOG()*(salePrice/1000);
    }
   
    receive() external payable {}
     
    function pause() external onlyOwner {
        _pause();
    }
   
    function unpause() external onlyOwner {
        _unpause();
    }
}