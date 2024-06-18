// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

interface IMessageChannel is IMessageStruct {
    /*
        /// @notice LaunchPad is the function that user or DApps send omni-chain message to other chain
        ///         Once the message is sent, the Relay will validate the message and send it to the target chain
        /// @dev 1. we will call the LaunchPad.Launch function to emit the message
        /// @dev 2. the message will be sent to the destination chain
        /// @param earliestArrivalTimestamp The earliest arrival time for the message
        ///        set to 0, vizing will forward the information ASAP.
        /// @param latestArrivalTimestamp The latest arrival time for the message
        ///        set to 0, vizing will forward the information ASAP.
        /// @param relayer the specify relayer for your message
        ///        set to 0, all the relayers will be able to forward the message
        /// @param sender The sender address for the message
        ///        most likely the address of the EOA, the user of some DApps
        /// @param value native token amount, will be sent to the target contract
        /// @param destChainid The destination chain id for the message
        /// @param additionParams The addition params for the message
        ///        if not in expert mode, set to 0 (`new bytes(0)`)
        /// @param message Arbitrary information
        ///
        ///    bytes                         
        ///   message  = abi.encodePacked(
        ///         byte1           uint256         uint24        uint64        bytes
        ///     messageType, activateContract, executeGasLimit, maxFeePerGas, signature
        ///   )
        ///        
    */
    function Launch(
        uint64 earliestArrivalTimestamp,
        uint64 latestArrivalTimestamp,
        address relayer,
        address sender,
        uint256 value,
        uint64 destChainid,
        bytes calldata additionParams,
        bytes calldata message
    ) external payable;

    ///
    ///    bytes                          byte1           uint256         uint24        uint64        bytes
    ///   message  = abi.encodePacked(messageType, activateContract, executeGasLimit, maxFeePerGas, signature)
    ///
    function launchMultiChain(
        launchEnhanceParams calldata params
    ) external payable;

    /// @notice batch landing message to the chain, execute the landing message
    /// @dev trusted relayer will call this function to send omni-chain message to the Station
    /// @param params the landing message params
    /// @param proofs the  proof of the validated message
    function Landing(
        landingParams[] calldata params,
        bytes[][] calldata proofs
    ) external payable;

    /// @notice similar to the Landing function, but with gasLimit
    function LandingSpecifiedGas(
        landingParams[] calldata params,
        uint24 gasLimit,
        bytes[][] calldata proofs
    ) external payable;

    /// @dev feel free to call this function before pass message to the Station,
    ///      this method will return the protocol fee that the message need to pay, longer message will pay more
    function estimateGas(
        uint256[] calldata value,
        uint64[] calldata destChainid,
        bytes[] calldata additionParams,
        bytes[] calldata message
    ) external view returns (uint256);

    function estimateGas(
        uint256 value,
        uint64 destChainid,
        bytes calldata additionParams,
        bytes calldata message
    ) external view returns (uint256);

    function estimatePrice(
        address sender,
        uint64 destChainid
    ) external view returns (uint64);

    function gasSystemAddr() external view returns (address);

    /// @dev get the message launch nonce of the sender on the specific chain
    /// @param chainId the chain id of the sender
    /// @param sender the address of the sender
    function GetNonceLaunch(
        uint64 chainId,
        address sender
    ) external view returns (uint32);

    /// @dev get the message landing nonce of the sender on the specific chain
    /// @param chainId the chain id of the sender
    /// @param sender the address of the sender
    function GetNonceLanding(
        uint64 chainId,
        address sender
    ) external view returns (uint32);

    /// @dev get the version of the Station
    /// @return the version of the Station, like "v1.0.0"
    function Version() external view returns (string memory);

    /// @dev get the chainId of current Station
    /// @return chainId, defined in the L2SupportLib.sol
    function Chainid() external view returns (uint64);

    function minArrivalTime() external view returns (uint64);

    function maxArrivalTime() external view returns (uint64);

    function expertLandingHook(bytes1 hook) external view returns (address);

    function expertLaunchHook(bytes1 hook) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

interface IMessageDashboard is IMessageStruct {
    /// @dev Only owner can call this function to stop or restart the engine
    /// @param stop true is stop, false is start
    function PauseEngine(bool stop) external;

    /// @notice return the states of the engine
    /// @return 0x01 is stop, 0x02 is start
    function engineState() external view returns (uint8);

    /// @notice return the states of the engine & Landing Pad
    function padState() external view returns (uint8, uint8);

    // function mptRoot() external view returns (bytes32);

    /// @dev withdraw the protocol fee from the contract, only owner can call this function
    /// @param amount the amount of the withdraw protocol fee
    function Withdraw(uint256 amount, address to) external;

    /// @dev set the payment system address, only owner can call this function
    /// @param gasSystemAddress the address of the payment system
    function setGasSystem(address gasSystemAddress) external;

    function setExpertLaunchHooks(
        bytes1[] calldata ids,
        address[] calldata hooks
    ) external;

    function setExpertLandingHooks(
        bytes1[] calldata ids,
        address[] calldata hooks
    ) external;

    /// notice reset the permission of the contract, only owner can call this function
    function roleConfiguration(
        bytes32 role,
        address[] calldata accounts,
        bool[] calldata states
    ) external;

    function stationAdminSetRole(
        bytes32 role,
        address[] calldata accounts,
        bool[] calldata states
    ) external;

    /// @notice transfer the ownership of the contract, only owner can call this function
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IMessageSpaceStation.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMessageEmitter {
    function minArrivalTime() external view returns (uint64);

    function maxArrivalTime() external view returns (uint64);

    function minGasLimit() external view returns (uint24);

    function maxGasLimit() external view returns (uint24);

    function defaultBridgeMode() external view returns (bytes1);

    function selectedRelayer() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

interface IMessageEvent is IMessageStruct {
    /// @notice Throws event after a  message which attempts to omni-chain is submitted to LaunchPad contract
    event SuccessfulLaunchMessage(
        uint32 indexed nonce,
        uint64 earliestArrivalTimestamp,
        uint64 latestArrivalTimestamp,
        address relayer,
        address sender,
        address srcContract,
        uint256 value,
        uint64 destChainid,
        bytes additionParams,
        bytes message
    );

    /// @notice Throws event after a  message which attempts to omni-chain is submitted to LaunchPad contract
    event SuccessfulLaunchMultiMessages(
        uint32[] indexed nonce,
        uint64 earliestArrivalTimestamp,
        uint64 latestArrivalTimestamp,
        address relayer,
        address sender,
        address srcContract,
        uint256[] value,
        uint64[] destChainid,
        bytes[] additionParams,
        bytes[] message
    );

    /// @notice Throws event after a omni-chain message is submitted from source chain to target chain
    event SuccessfulLanding(bytes32 indexed messageId, landingParams params);

    /// @notice Throws event after protocol state is changed, such as pause or resume
    event EngineStateRefreshing(bool indexed isPause);

    /// @notice Throws event after protocol fee calculation is changed
    event PaymentSystemChanging(address indexed gasSystemAddress);

    /// @notice Throws event after successful withdrawa
    event WithdrawRequest(address indexed to, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMessageReceiver {
    function receiveStandardMessage(
        uint64 srcChainId,
        uint256 srcContract,
        bytes calldata message
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";

interface IMessageSimulation is IMessageStruct {
    /// @dev for sequencer to simulate the landing message, call this function before call Landing
    /// @param params the landing message params
    /// check the revert message "SimulateResult" to get the result of the simulation
    /// for example, if the result is [true, false, true], it means the first and third message is valid, the second message is invalid
    function SimulateLanding(landingParams[] calldata params) external payable;

    /// @dev call this function off-chain to estimate the gas of excute the landing message
    /// @param params the landing message params
    /// @return the result of the estimation, true is valid, false is invalid
    function EstimateExecuteGas(
        landingParams[] calldata params
    ) external returns (bool[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./IMessageStruct.sol";
import {IMessageDashboard} from "./IMessageDashboard.sol";
import {IMessageEvent} from "../interface/IMessageEvent.sol";
import {IMessageChannel} from "../interface/IMessageChannel.sol";
import {IMessageSimulation} from "../interface/IMessageSimulation.sol";

interface IMessageSpaceStation is
    IMessageStruct,
    IMessageDashboard,
    IMessageEvent,
    IMessageChannel,
    IMessageSimulation
{}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMessageStruct {
    struct launchParams {
        uint64 earliestArrivalTimestamp;
        uint64 latestArrivalTimestamp;
        address relayer;
        address sender;
        uint256 value;
        uint64 destChainid;
        bytes additionParams;
        bytes message;
    }

    struct landingParams {
        bytes32 messageId;
        uint64 earliestArrivalTimestamp;
        uint64 latestArrivalTimestamp;
        uint64 srcChainid;
        bytes32 srcTxHash;
        uint256 srcContract;
        uint32 srcChainNonce;
        uint256 sender;
        uint256 value;
        bytes additionParams;
        bytes message;
    }

    struct launchEnhanceParams {
        uint64 earliestArrivalTimestamp;
        uint64 latestArrivalTimestamp;
        address relayer;
        address sender;
        uint256[] value;
        uint64[] destChainid;
        bytes[] additionParams;
        bytes[] message;
    }

    struct RollupMessageStruct {
        SignedMessageBase base;
        IMessageStruct.launchParams params;
    }

    struct SignedMessageBase {
        uint64 srcChainId;
        uint24 nonceLaunch;
        bytes32 srcTxHash;
        bytes32 destTxHash;
        uint64 srcTxTimestamp;
        uint64 destTxTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IVizingGasSystemChannel {
    /*
        /// @notice Estimate how many native token we should spend to exchange the amountOut in the destChainid
        /// @param destChainid The chain id of the destination chain
        /// @param amountOut The value we want to receive in the destination chain
        /// @return amountIn the native token amount on the source chain we should spend
    */
    function exactOutput(
        uint64 destChainid,
        uint256 amountOut
    ) external view returns (uint256 amountIn);

    /*
        /// @notice Estimate how many native token we could get in the destChainid if we input the amountIn
        /// @param destChainid The chain id of the destination chain
        /// @param amountIn The value we spent in the source chain
        /// @return amountOut the native token amount the destination chain will receive
    */
    function exactInput(
        uint64 destChainid,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    /*
        /// @notice Estimate the gas fee we should pay to vizing
        /// @param destChainid The chain id of the destination chain
        /// @param message The message we want to send to the destination chain
    */
    function estimateGas(
        uint256 amountOut,
        uint64 destChainid,
        bytes calldata message
    ) external view returns (uint256);

    /*
        /// @notice Estimate the gas fee & native token we should pay to vizing
        /// @param amountOut amountOut in the destination chain
        /// @param destChainid The chain id of the destination chain
        /// @param message The message we want to send to the destination chain
    */
    function batchEstimateTotalFee(
        uint256[] calldata amountOut,
        uint64[] calldata destChainid,
        bytes[] calldata message
    ) external view returns (uint256 totalFee);

    /*
        /// @notice Estimate the total fee we should pay to vizing
        /// @param value The value we spent in the source chain
        /// @param destChainid The chain id of the destination chain
        /// @param message The message we want to send to the destination chain
    */
    function estimateTotalFee(
        uint256 value,
        uint64 destChainid,
        bytes calldata message
    ) external view returns (uint256 totalFee);

    /*
        /// @notice Estimate the gas price we need to encode in message
        /// @param sender most likely the address of the DApp, which forward the message from user
        /// @param destChainid The chain id of the destination chain
    */
    function estimatePrice(
        address targetContract,
        uint64 destChainid
    ) external view returns (uint64);

    /*
        /// @notice Estimate the gas price we need to encode in message
        /// @param destChainid The chain id of the destination chain
    */
    function estimatePrice(uint64 destChainid) external view returns (uint64);

    /*
        /// @notice Calculate the fee for the native token transfer
        /// @param amount The value we spent in the source chain
    */
    function computeTradeFee(
        uint64 destChainid,
        uint256 amountOut
    ) external view returns (uint256 fee);

    /*
        /// @notice Calculate the fee for the native token transfer
        /// @param amount The value we spent in the source chain
    */
    function computeTradeFee(
        address targetContract,
        uint64 destChainid,
        uint256 amountOut
    ) external view returns (uint256 fee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library MessageTypeLib {
    bytes1 constant DEFAULT = 0x00;

    /* ********************* message type **********************/
    bytes1 constant STANDARD_ACTIVATE = 0x01;
    bytes1 constant ARBITRARY_ACTIVATE = 0x02;
    bytes1 constant MESSAGE_POST = 0x03;
    bytes1 constant NATIVE_TOKEN_SEND = 0x04;

    /**
     * additionParams type *********************
     */
    // Single-Send mode
    bytes1 constant SINGLE_SEND = 0x01;
    bytes1 constant ERC20_HANDLER = 0x03;
    bytes1 constant MULTI_MANY_2_ONE = 0x04;
    bytes1 constant MULTI_UNIVERSAL = 0x05;

    bytes1 constant MAX_MODE = 0xFF;

    function fetchMsgMode(
        bytes calldata message
    ) internal pure returns (bytes1) {
        if (message.length < 1) {
            return DEFAULT;
        }
        bytes1 messageSlice = bytes1(message[0:1]);
        return messageSlice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageStruct} from "./interface/IMessageStruct.sol";
import {IMessageChannel} from "./interface/IMessageChannel.sol";
import {IMessageEmitter} from "./interface/IMessageEmitter.sol";
import {IMessageReceiver} from "./interface/IMessageReceiver.sol";
import {IVizingGasSystemChannel} from "./interface/IVizingGasSystemChannel.sol";

abstract contract MessageEmitter is IMessageEmitter {
    /// @dev bellow are the default parameters for the OmniToken,
    ///      we **Highly recommended** to use immutable variables to store these parameters
    /// @notice minArrivalTime the minimal arrival timestamp for the omni-chain message
    /// @notice maxArrivalTime the maximal arrival timestamp for the omni-chain message
    /// @notice minGasLimit the minimal gas limit for target chain execute omni-chain message
    /// @notice maxGasLimit the maximal gas limit for target chain execute omni-chain message
    /// @notice defaultBridgeMode the default mode for the omni-chain message,
    ///        in OmniToken, we use MessageTypeLib.ARBITRARY_ACTIVATE (0x02), target chain will **ACTIVATE** the message
    /// @notice selectedRelayer the specify relayer for your message
    ///        set to 0, all the relayers will be able to forward the message
    /// see https://docs.vizing.com/docs/BuildOnVizing/Contract

    function minArrivalTime() external view virtual override returns (uint64) {}

    function maxArrivalTime() external view virtual override returns (uint64) {}

    function minGasLimit() external view virtual override returns (uint24) {}

    function maxGasLimit() external view virtual override returns (uint24) {}

    function defaultBridgeMode()
        external
        view
        virtual
        override
        returns (bytes1)
    {}

    function selectedRelayer()
        external
        view
        virtual
        override
        returns (address)
    {}

    IMessageChannel public LaunchPad;

    constructor(address _LaunchPad) {
        __LaunchPadInit(_LaunchPad);
    }

    /*
        /// rewrite set LaunchPad address function
        /// @notice call this function to reset the LaunchPad contract address
        /// @param _LaunchPad The new LaunchPad contract address
    */
    function __LaunchPadInit(address _LaunchPad) internal virtual {
        LaunchPad = IMessageChannel(_LaunchPad);
    }

    /*
        /// @notice call this function to packet the message before sending it to the LandingPad contract
        /// @param mode the emitter mode, check MessageTypeLib.sol for more details
        ///        eg: 0x02 for ARBITRARY_ACTIVATE, your message will be activated on the target chain
        /// @param gasLimit the gas limit for executing the specific function on the target contract
        /// @param targetContract the target contract address on the destination chain
        /// @param message the message to be sent to the target contract
        /// @return the packed message
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function _packetMessage(
        bytes1 mode,
        address targetContract,
        uint24 gasLimit,
        uint64 price,
        bytes memory message
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                mode,
                uint256(uint160(targetContract)),
                gasLimit,
                price,
                message
            );
    }

    /*
        /// @notice use this function to send the ERC20 token to the destination chain
        /// @param tokenSymbol The token symbol
        /// @param sender The sender address for the message
        /// @param receiver The receiver address for the message
        /// @param amount The amount of tokens to be sent
        /// see https://docs.vizing.com/docs/DApp/Omni-ERC20-Transfer
    */
    function _packetAdditionParams(
        bytes1 mode,
        bytes1 tokenSymbol,
        address sender,
        address receiver,
        uint256 amount
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(mode, tokenSymbol, sender, receiver, amount);
    }

    /*
        /// @notice Calculate the amount of native tokens obtained on the target chain
        /// @param value The value we send to vizing on the source chain
    */
    function _computeTradeFee(
        uint64 destChainid,
        uint256 value
    ) internal view returns (uint256 amountIn) {
        return
            IVizingGasSystemChannel(LaunchPad.gasSystemAddr()).computeTradeFee(
                destChainid,
                value
            );
    }

    /*
        /// @notice Fetch the nonce of the user with specific destination chain
        /// @param destChainid The chain id of the destination chain
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function _fetchNonce(
        uint64 destChainid
    ) internal view virtual returns (uint32 nonce) {
        nonce = LaunchPad.GetNonceLaunch(destChainid, msg.sender);
    }

    /*
        /// @notice Estimate the gas price we need to encode in message
        /// @param destChainid The chain id of the destination chain
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function _fetchPrice(
        uint64 destChainid
    ) internal view virtual returns (uint64) {
        return
            IVizingGasSystemChannel(LaunchPad.gasSystemAddr()).estimatePrice(
                destChainid
            );
    }

    /*
        /// @notice Estimate the gas price we need to encode in message
        /// @param targetContract The target contract address on the destination chain
        /// @param destChainid The chain id of the destination chain
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function _fetchPrice(
        address targetContract,
        uint64 destChainid
    ) internal view virtual returns (uint64) {
        return
            IVizingGasSystemChannel(LaunchPad.gasSystemAddr()).estimatePrice(
                targetContract,
                destChainid
            );
    }

    /*
        /// @notice similar to uniswap Swap Router
        /// @notice Estimate how many native token we should spend to exchange the amountOut in the destChainid
        /// @param destChainid The chain id of the destination chain
        /// @param amountOut The value we want to exchange in the destination chain
        /// @return amountIn the native token amount on the source chain we should spend
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function _exactOutput(
        uint64 destChainid,
        uint256 amountOut
    ) internal view returns (uint256 amountIn) {
        return
            IVizingGasSystemChannel(LaunchPad.gasSystemAddr()).exactOutput(
                destChainid,
                amountOut
            );
    }

    /*
        /// @notice similar to uniswap Swap Router
        /// @notice Estimate how many native token we could get in the destChainid if we input the amountIn
        /// @param destChainid The chain id of the destination chain
        /// @param amountIn The value we spent in the source chain
        /// @return amountOut the native token amount the destination chain will receive
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function _exactInput(
        uint64 destChainid,
        uint256 amountIn
    ) internal view returns (uint256 amountOut) {
        return
            IVizingGasSystemChannel(LaunchPad.gasSystemAddr()).exactInput(
                destChainid,
                amountIn
            );
    }

    /*
        /// @notice Estimate the gas price we need to encode in message
        /// @param value The native token that value target address will receive in the destination chain
        /// @param destChainid The chain id of the destination chain
        /// @param additionParams The addition params for the message
        ///        if not in expert mode, set to 0 (`new bytes(0)`)
        /// @param message The message we want to send to the destination chain
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function _estimateVizingGasFee(
        uint256 value,
        uint64 destChainid,
        bytes memory additionParams,
        bytes memory message
    ) internal view returns (uint256 vizingGasFee) {
        return
            LaunchPad.estimateGas(value, destChainid, additionParams, message);
    }

    /*  
        /// @notice **Highly recommend** to call this function in your frontend program
        /// @notice Estimate the gas price we need to encode in message
        /// @param value The native token that value target address will receive in the destination chain
        /// @param destChainid The chain id of the destination chain
        /// @param additionParams The addition params for the message
        ///        if not in expert mode, set to 0 (`new bytes(0)`)
        /// @param message The message we want to send to the destination chain
        /// see https://docs.vizing.com/docs/BuildOnVizing/Contract
    */
    function estimateVizingGasFee(
        uint256 value,
        uint64 destChainid,
        bytes calldata additionParams,
        bytes calldata message
    ) external view returns (uint256 vizingGasFee) {
        return
            _estimateVizingGasFee(value, destChainid, additionParams, message);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IMessageChannel} from "./interface/IMessageChannel.sol";
import {IMessageReceiver} from "./interface/IMessageReceiver.sol";

abstract contract MessageReceiver is IMessageReceiver {
    error LandingPadAccessDenied();
    error NotImplement();
    IMessageChannel public LandingPad;

    modifier onlyVizingPad() {
        if (msg.sender != address(LandingPad)) revert LandingPadAccessDenied();
        _;
    }

    constructor(address _LandingPad) {
        __LandingPadInit(_LandingPad);
    }

    /*
        /// rewrite set LandingPad address function
        /// @notice call this function to reset the LaunchPad contract address
        /// @param _LaunchPad The new LaunchPad contract address
    */
    function __LandingPadInit(address _LandingPad) internal virtual {
        LandingPad = IMessageChannel(_LandingPad);
    }

    /// @notice the standard function to receive the omni-chain message
    function receiveStandardMessage(
        uint64 srcChainId,
        uint256 srcContract,
        bytes calldata message
    ) external payable virtual override onlyVizingPad {
        _receiveMessage(srcChainId, srcContract, message);
    }

    /// @dev override this function to handle the omni-chain message
    /// @param srcChainId the source chain id
    /// @param srcContract the source contract address
    /// @param message the message from the source chain
    function _receiveMessage(
        uint64 srcChainId,
        uint256 srcContract,
        bytes calldata message
    ) internal virtual {
        (srcChainId, srcContract, message);
        revert NotImplement();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MessageEmitter} from "./MessageEmitter.sol";
import {MessageReceiver} from "./MessageReceiver.sol";

abstract contract VizingOmni is MessageEmitter, MessageReceiver {
    constructor(
        address _vizingPad
    ) MessageEmitter(_vizingPad) MessageReceiver(_vizingPad) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {VizingOmni} from "@vizing/contracts/VizingOmni.sol";
import {MessageTypeLib} from "@vizing/contracts/library/MessageTypeLib.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


import "./ExcessivelySafeCall.sol";
import "./NonblockingApp.sol";

abstract contract ERC314PlusCore is ERC20, Ownable, ReentrancyGuard, VizingOmni, NonblockingApp, Pausable {
    using ExcessivelySafeCall for address;

    enum ActionType {
        depositPing,
        depositPong,
        launch,
        claimPing,
        claimPong,
        buyPing,
        buyPong,
        sellPing,
        sellPong,
        crossPing
    }
    struct DebitAmount {
        uint native;
        uint token;
    }
    
    function pause() external onlyOwner {
        bool isPaused = paused() ;
        if(isPaused) {
            _unpause();
        } else {
            _pause();
        }
    }

    event MessageReceived(uint64 _srcChainId, address _srcAddress, uint value, bytes _payload);
    event PongfeeFailed(uint64 _srcChainId, address _srcAddress, uint8 _action, uint _pongFee, uint _expectPongFee);
    event Launch(
        uint earmarkedSupply,
        uint earmarkedNative,
        uint presaleRefundRatio,
        uint presaleSupply,
        uint presaleNative,
        uint omniSupply,
        uint presaleAccumulate
    );
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out,uint nonce);
    event AssetLocked(ActionType _action, uint64 _srcChainId, address _owner, uint _lockedNative, uint _lockedToken,uint nonce);
    event Deposited(uint64 _srcChainId, address _sender, uint _native,uint nonce);
    event Claimed(uint64 _srcChainId, address _sender, address _to, uint _native, uint _token,uint nonce);
    event Crossed(uint64 _srcChainId, address _sender, address _to, uint _token,uint nonce);
    event Unlocked(address _owner,address _to, uint _native, uint _token);

    uint64 public immutable override minArrivalTime;
    uint64 public immutable override maxArrivalTime;
    uint24 public immutable override minGasLimit;
    uint24 public immutable override maxGasLimit;
    bytes1 public immutable override defaultBridgeMode;
    address public immutable override selectedRelayer;

    mapping(uint => mapping(address => mapping(uint => bool))) public crossNoncePing;
    mapping(uint => mapping(address => uint)) public crossNonce;


    uint64 public masterChainId;
    bool public launched;
    uint public messageReceived;
    address public feeAddress;
    uint public totalSupplyInit = 20000000 ether;
    uint public launchFunds = 10 ether;
    uint public launchHardCap = 8000 ether;
    uint public tokenomics = 2;
    address public airdropAddr;
    function setFeeAddress(address addr) public virtual onlyOwner {
        feeAddress = addr;
    }
    function setAirdropAddr(address addr) public virtual onlyOwner {
        airdropAddr = addr;
    }
    function setLaunchHardCap(uint amount) public virtual onlyOwner {
        launchHardCap = amount;
    }

    uint MAX_INT = 2 ** 256 - 1;
    uint public nativeMax = 50 ether;
    function setNativeMax(uint amount) public virtual onlyOwner {
        nativeMax = amount;
    }

    uint public nativeMin = 0.0001 ether;
    function setNativeMin(uint amount) public virtual onlyOwner {
        nativeMin = amount;
    }

    uint public tokenMin = 1 ether;
    function setTokenMin(uint amount) public virtual onlyOwner {
        tokenMin = amount;
    }
    uint public launchTime = 1718956800;
    function setLaunchTime(uint launchTime_) public virtual onlyOwner {
        launchTime = launchTime_;
    }
    function launchIsEnd() public view returns (bool)  {
        return block.timestamp >= launchTime;
    }
    function nowTime() public view returns (uint)  {
        return block.timestamp;
    }
    constructor(
        string memory _name,
        string memory _symbol,
        address _vizingPad,
        uint64 _masterChainId
    ) VizingOmni(_vizingPad) ERC20(_name, _symbol) {
        masterChainId = _masterChainId;
        launched = false;
        defaultBridgeMode = MessageTypeLib.STANDARD_ACTIVATE;
        feeAddress = owner();
        airdropAddr = owner();
    }

    //----vizing bridge common----
    function paramsEstimateGas(
        uint64 dstChainId,
        address dstContract,
        uint value,
        bytes memory params
    ) public view virtual returns (uint) {
        bytes memory message = _packetMessage(
            defaultBridgeMode,
            dstContract,
            maxGasLimit,
            _fetchPrice(dstContract, dstChainId),
            abi.encode(_msgSender(), params)
        );
        return LaunchPad.estimateGas(value, dstChainId, new bytes(0), message);
    }

    function paramsEmit2LaunchPad(
        uint bridgeFee,
        uint64 dstChainId,
        address dstContract,
        uint value,
        bytes memory params,
        address sender
    ) internal virtual {
        bytes memory message = _packetMessage(
            defaultBridgeMode,
            dstContract,
            maxGasLimit,
            _fetchPrice(dstContract, dstChainId),
            abi.encode(_msgSender(), params)
        );
        /*
        emit2LaunchPad(
            0, //uint64(block.timestamp + minArrivalTime),
            0, //uint64(block.timestamp + maxArrivalTime),
            selectedRelayer,
            sender,
            value,
            dstChainId,
            new bytes(0),
            message
        );
        */
        uint bridgeValue = value + bridgeFee;
        require(msg.value >= bridgeValue, "bridgeFee err.");
        LaunchPad.Launch{value: bridgeValue}(0, 0, selectedRelayer, sender, value, dstChainId, new bytes(0), message);
    }

    //----  message call function----

    function master_deposit(
        uint pongFee,
        uint64 srcChainId,
        address sender,
        address target,
        uint amount,
        uint nonce
    ) internal virtual {
        revert NotImplement();
    }

    function master_claim(uint pongFee, uint64 srcChainId, address sender, address target,uint nonce) internal virtual {
        revert NotImplement();
    }

    function master_buy(uint pongFee, uint64 srcChainId, address sender, address target, uint native,uint nonce ) internal virtual {
        revert NotImplement();
    }

    function master_sell(uint pongFee, uint64 srcChainId, address sender, address target, uint token,uint nonce) internal virtual {
        revert NotImplement();
    }

    function slave_launch(uint64 srcChainId, address sender) internal virtual {
        revert NotImplement();
    }

    function slave_deposit(uint64 srcChainId, address sender, address target, uint amount, uint accumulate,uint nonce) internal virtual {
        revert NotImplement();
    }

    function slave_claim(uint64 srcChainId, address sender, address target, uint native, uint token,uint nonce) internal virtual {
        revert NotImplement();
    }

    function slave_buy(uint64 srcChainId, address sender, address target, uint native, uint token,uint nonce) internal virtual {
        revert NotImplement();
    }

    function slave_sell(uint64 srcChainId, address sender, address target, uint native, uint token,uint nonce) internal virtual {
        revert NotImplement();
    }

    function master_cross(
        uint64 srcChainId,
        address sender,
        uint64 dstChainId,
        address to,
        uint token,
        uint nonce
    ) internal virtual {
        revert NotImplement();
    }

    function slave_cross(
        uint64 srcChainId,
        address sender,
        uint64 dstChainId,
        address to,
        uint token,
        uint nonce
    ) internal virtual {
        revert NotImplement();
    }

    function action_master(
        uint64 srcChainId,
        address sender,
        uint8 action,
        uint pongFee,
        bytes memory params
    ) internal virtual {
        if (action == uint8(ActionType.depositPing)) {
            (uint nonce ,address target, uint amount) = abi.decode(params, (uint, address, uint));
            master_deposit(pongFee, srcChainId, sender, target, amount,nonce);
        } else if (action == uint8(ActionType.claimPing)) {
            (uint nonce ,address target) = abi.decode(params, (uint,address));
            master_claim(pongFee, srcChainId, sender, target,nonce);
        } else if (action == uint8(ActionType.buyPing)) {
            (uint nonce ,address target, uint native) = abi.decode(params, (uint,address, uint));
            master_buy(pongFee, srcChainId, sender, target, native,nonce);
        } else if (action == uint8(ActionType.sellPing)) {
            (uint nonce,address target, uint token) = abi.decode(params, (uint,address, uint));
            master_sell(pongFee, srcChainId, sender, target, token,nonce);
        } else if (action == uint8(ActionType.crossPing)) {
            (uint nonce,uint64 chainid, address to, uint token) = abi.decode(params, (uint,uint64, address, uint));
            master_cross(srcChainId, sender, chainid, to, token,nonce);
        } else revert NotImplement();
    }

    function action_slave(
        uint64 srcChainId,
        address sender,
        uint8 action,
        uint pongFee,
        bytes memory params
    ) internal virtual {
        if (action == uint8(ActionType.depositPong)) {
            (uint nonce,address target, uint amount,uint accumulate) = abi.decode(params, (uint,address, uint, uint));
            slave_deposit(srcChainId, sender, target, amount, accumulate,nonce);
        } else if (action == uint8(ActionType.claimPong)) {
            (uint nonce,address target, uint native, uint token) = abi.decode(params, (uint, address, uint, uint));
            slave_claim(srcChainId, sender, target, native, token,nonce);
        } else if (action == uint8(ActionType.buyPong)) {
            (uint nonce,address target, uint native, uint token) = abi.decode(params, (uint,address, uint, uint));
            slave_buy(srcChainId, sender, target, native, token,nonce);
        } else if (action == uint8(ActionType.sellPong)) {
            (uint nonce,address target, uint token, uint native) = abi.decode(params, (uint,address, uint, uint));
            slave_sell(srcChainId, sender, target, native, token,nonce);
        } else if (action == uint8(ActionType.launch)) {
            slave_launch(srcChainId, sender);
        } else if (action == uint8(ActionType.crossPing)) {
            (uint nonce,uint64 chainid, address to, uint token) = abi.decode(params, (uint,uint64, address, uint));
            slave_cross(srcChainId, sender, chainid, to, token,nonce);
        } else revert NotImplement();
    }

    //---- message----

    function _computePongValueWithOutPongFee(
        uint8 action,
        uint64 srcChainId,
        uint pongFee,
        bytes memory params
    ) internal view virtual returns (uint value, uint sendToFee) {
        value = msg.value - pongFee;
        sendToFee = 0;
    }

    function _nonblockingReceive(
        uint64 srcChainId,
        address sender,
        uint8 action,
        uint pongFee,
        bytes calldata params
    ) public payable virtual override {
        require(_msgSender() == address(this), "ERC314PlusCore: caller must be self");
        if (srcChainId == masterChainId) action_slave(srcChainId, sender, action, pongFee, params);
        else action_master(srcChainId, sender, action, pongFee, params);
    }

    function _callSelf(
        uint64 srcChainId,
        address sender,
        uint8 action,
        uint pongFee,
        uint callValue,
        bytes memory params
    ) internal returns (bool success, bytes memory reason) {
        (success, reason) = address(this).excessivelySafeCall(
            gasleft(),
            callValue,
            150,
            abi.encodeWithSelector(this._nonblockingReceive.selector, srcChainId, sender, action, pongFee, params)
        );
    }

    function verifySource(uint64 srcChainId, address srcContract) internal view virtual returns (bool authorized);

    function _receiveMessage(
        uint64 srcChainId,
        uint256 srcContract,
        bytes calldata _payload
    ) internal virtual override {
        require(verifySource(srcChainId, address(uint160(srcContract))), "unauthorized.");
        (address sender, bytes memory message) = abi.decode(_payload, (address, bytes));
        messageReceived += 1;
        emit MessageReceived(srcChainId, sender, msg.value, message);

        (uint8 action, uint pongFee, bytes memory params) = abi.decode(message, (uint8, uint, bytes));

        (uint value, uint sendToFee) = _computePongValueWithOutPongFee(action, srcChainId, pongFee, params);
        uint callValue = pongFee + value - sendToFee;
        if (sendToFee > 0)
            transferNative(feeAddress, sendToFee);
        (bool success, bytes memory reason) = _callSelf(srcChainId, sender, action, pongFee, callValue, params);
        if (!success) {
            _storeFailedMessage(srcChainId, sender, message, reason, callValue);
        }
        require(success, "cross-chain failed");
    }
    
    function transferNative(address to, uint amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        if (_msgSender() != address(this) && to == address(this)) {
            revert("Unsupported");
        } else {
            super._transfer(from, to, amount);
        }
    }

    //----Signature---
    /*
    function _fetchSignature(bytes memory message) internal view virtual returns (bytes memory signature) {
        //signature = abi.encodeCall(this.receiveMessage, (deployChainId, address(this), msg.sender, message));
        signature = message;
    }
    */

    function _depositPingSignature(
        uint nonce,
        address target,
        uint pongFee,
        uint amount
    ) internal view virtual returns (bytes memory) {
        return abi.encode(uint8(ActionType.depositPing), pongFee, abi.encode(nonce,target, amount));
    }
    function _depositPongSignature(
        uint nonce,
        address target,
        uint pongFee,
        uint amount,
        uint accumulate
    ) internal view virtual returns (bytes memory) {
        return abi.encode(uint8(ActionType.depositPong), pongFee, abi.encode(nonce,target, amount,accumulate));
    }

    function _claimPingSignature(uint nonce,address target, uint pongFee) internal view virtual returns (bytes memory) {
        return abi.encode(uint8(ActionType.claimPing), pongFee, abi.encode(nonce,target));
    }

    function _claimPongSignature(
        uint nonce,
        address target,
        uint refund,
        uint amount
    ) internal view virtual returns (bytes memory) {
        return abi.encode(uint8(ActionType.claimPong), 0, abi.encode(nonce,target, refund, amount));
    }

    function _buyPingSignature(
        uint nonce,
        address target,
        uint pongFee,
        uint amountIn
    ) internal view virtual returns (bytes memory) {
        return abi.encode(uint8(ActionType.buyPing), pongFee, abi.encode(nonce,target, amountIn));
    }

    function _buyPongSignature(uint nonce,address target, uint native, uint token) internal view virtual returns (bytes memory) {
        return abi.encode(uint8(ActionType.buyPong), 0, abi.encode(nonce,target, native, token));
    }

    function _sellPingSignature(
        uint nonce,
        address target,
        uint pongFee,
        uint amountIn
    ) internal view virtual returns (bytes memory) {
        return abi.encode(uint8(ActionType.sellPing), pongFee, abi.encode(nonce,target, amountIn));
    }

    function _sellPongSignature(uint nonce,address target, uint native, uint token) internal view virtual returns (bytes memory) {
        return abi.encode(uint8(ActionType.sellPong), 0, abi.encode(nonce,target, native, token));
    }

    function _crossPingSignature(
        uint nonce,
        uint64 dstChainId,
        address target,
        uint token
    ) internal view virtual returns (bytes memory) {
        return abi.encode(uint8(ActionType.crossPing), 0, abi.encode(nonce,dstChainId, target, token));
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _value The value in wei to send to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint256 _value,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                _value, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf) internal pure {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ExcessivelySafeCall.sol";

abstract contract NonblockingApp {
    //mapping(uint64 => mapping(address => bytes32)) public failedMessages;
    uint public messageFailed;

    event MessageFailed(
        uint64 _srcChainId,
        address _srcAddress,
        bytes _payload,
        bytes _reason,
        uint _value,
        uint _callValue
    );
    event RetryMessageSuccess(uint64 _srcChainId, address _srcAddress, bytes32 _payloadHash);

    function _nonblockingReceive(
        uint64 srcChainId,
        address sender,
        uint8 action,
        uint pongFee,
        bytes calldata message
    ) public payable virtual;

    function _storeFailedMessage(
        uint64 _srcChainId,
        address _srcAddress,
        bytes memory _payload,
        bytes memory _reason,
        uint _callValue
    ) internal virtual {
        messageFailed += 1;
        //failedMessages[_srcChainId][_srcAddress] = keccak256(_payload);
        emit MessageFailed(_srcChainId, _srcAddress, _payload, _reason, msg.value, _callValue);
    }
    /*
    function retryMessage(uint64 _srcChainId, address _srcAddress, bytes calldata _payload) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress];
        require(payloadHash != bytes32(0), "NonblockingApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingApp: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingReceive(_srcChainId, _srcAddress, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, payloadHash);
    }
    */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ERC314PlusCore} from "./ERC314PlusCore.sol";
import {IMessageStruct} from "@vizing/contracts/interface/IMessageStruct.sol";


contract SlaveTokenBase is ERC314PlusCore {
    address public masterContract;

    constructor(
        string memory _name,
        string memory _symbol,
        address _vizingPad,
        address _defaultRelayer,
        uint64 _masterChainId
    ) ERC314PlusCore(_name, _symbol, _vizingPad, _masterChainId) {
        minArrivalTime = 1 minutes;
        maxArrivalTime = 1 days;
        minGasLimit = 100000;
        maxGasLimit = 1000000;
        selectedRelayer = _defaultRelayer;
    }
    mapping(address => uint) public deposited; //local chain deposited address=>amount
    mapping(address => uint) public depositPing;
    mapping(address => bool) public claimed;
    mapping(address => uint) public depositNonce;
    mapping(address => mapping(uint => bool)) public depositNoncePong;

    mapping(address => uint) public claimNonce;
    mapping(address => mapping(uint => bool)) public claimNoncePong;

    mapping(address => uint) public buyNonce;
    mapping(address => mapping(uint => bool)) public buyNoncePong;

    mapping(address => uint) public sellNonce;
    mapping(address => mapping(uint => bool)) public sellNoncePong;
    uint public calcAccumulate;

    function setMasterContract(address addr) public virtual onlyOwner {
        masterContract = addr;
    }

    function verifySource(
        uint64 srcChainId,
        address srcContract
    ) internal view virtual override returns (bool authorized) {
        return masterContract == srcContract && masterChainId == srcChainId;
    }

    //----slave call
    function slave_launch(uint64 srcChainId, address sender) internal virtual override {
        launched = true;
    }

    function slave_deposit(uint64 srcChainId, address sender, address target, uint amount,uint accumulate,uint nonce) internal virtual override {
        require(!depositNoncePong[target][nonce], "nonce repetition");
        depositNoncePong[target][nonce] = true;
        deposited[target] += amount;
        if(accumulate > calcAccumulate){
            calcAccumulate = accumulate;
        }
    }

    function slave_claim(
        uint64 srcChainId,
        address sender,
        address target,
        uint native,
        uint token,
        uint nonce
    ) internal virtual override {
        require(!claimNoncePong[target][nonce], "nonce repetition");
        claimNoncePong[target][nonce] = true;
        require(!claimed[target], "claim repetition");
        if (token > 0) _mint(target, token);
        if (native > 0) payable(target).transfer(native);
        claimed[target] = true;
    }

    function slave_buy(
        uint64 srcChainId,
        address sender,
        address target,
        uint native,
        uint token,
        uint nonce
    ) internal virtual override {
        require(!buyNoncePong[target][nonce], "nonce repetition");
        buyNoncePong[target][nonce] = true;
        if (token > 0) _mint(target, token);
        if (native > 0) payable(target).transfer(native);
    }

    function slave_sell(
        uint64 srcChainId,
        address sender,
        address target,
        uint native,
        uint token,
        uint nonce
    ) internal virtual override {
        require(!sellNoncePong[target][nonce], "nonce repetition");
        sellNoncePong[target][nonce] = true;
        if (token > 0) _mint(target, token);
        if (native > 0) payable(target).transfer(native);
    }

    //----deposit
    function depositPingEstimateGas(
        uint pongFee,
        address target,
        uint amount
    ) public view virtual returns (uint pingFee) {
        uint nonce = depositNonce[target];
        pingFee = paramsEstimateGas(
            masterChainId,
            masterContract,
            amount + pongFee,
            _depositPingSignature(nonce+1, target, pongFee, amount)
        );
    }

    function deposit(uint pongFee, uint amount) public payable virtual nonReentrant whenNotPaused {
        require(!launchIsEnd(),"deposit end");
        require(!launched, "launched");
        uint pingFee = depositPingEstimateGas(pongFee, _msgSender(), amount);
        require(msg.value >= amount + pingFee + pongFee, "bridge fee not enough");
        require(depositPing[_msgSender()] + amount <= nativeMax,"exceeding the maximum value");
        require(calcAccumulate <= launchHardCap,"hard cap");
        depositPing[_msgSender()] += amount;
        uint nonce = depositNonce[_msgSender()];
        paramsEmit2LaunchPad(
            pingFee,
            masterChainId,
            masterContract,
            amount + pongFee,
            _depositPingSignature(nonce+1, _msgSender(), pongFee, amount),
            _msgSender()
        );
        depositNonce[_msgSender()]++;
    }

    //----claim

    function claimPingEstimateGas(uint pongFee, address target) public view virtual returns (uint pingFee) {
        uint nonce = claimNonce[_msgSender()];
        pingFee = paramsEstimateGas(masterChainId, masterContract, pongFee, _claimPingSignature(nonce+1,target, pongFee));
    }

    function claim(uint pongFee) public payable virtual nonReentrant whenNotPaused{
        require(launched, "unlaunched");
        require(!claimed[_msgSender()], "claimed");
        uint pingFee = claimPingEstimateGas(pongFee, _msgSender());
        require(msg.value >= pingFee + pongFee, "bridge fee not enough");
        uint nonce = claimNonce[_msgSender()];
        paramsEmit2LaunchPad(
            pingFee,
            masterChainId,
            masterContract,
            pongFee,
            _claimPingSignature(nonce+1,_msgSender(), pongFee),
            _msgSender()
        );
        claimNonce[_msgSender()]++;
    }

    //----_buy

    function buyPingEstimateGas(
        uint pongFee,
        address target,
        uint amountIn
    ) public view virtual returns (uint pingFee) {
        uint nonce = buyNonce[_msgSender()];
        pingFee = paramsEstimateGas(
            masterChainId,
            masterContract,
            pongFee,
            _buyPingSignature(nonce+1,target, pongFee, amountIn)
        );
    }

    function _buy(uint pongFee, address to, uint deadline) internal {
        require(launched, "unlaunched");
        require(deadline == 0 || deadline > block.timestamp, "deadline err.");
        uint pingFee = buyPingEstimateGas(pongFee, to, msg.value);
        uint amountIn = msg.value - pingFee - pongFee;
        require(amountIn >= nativeMin, "the amount cannot be too small");
        require(amountIn <= nativeMax,"the amount cannot be too large");
        uint nonce = buyNonce[_msgSender()];
        paramsEmit2LaunchPad(
            pingFee,
            masterChainId,
            masterContract,
            amountIn + pongFee,
            _buyPingSignature(nonce+1,to, pongFee, amountIn),
            _msgSender()
        );
        buyNonce[_msgSender()]++;
    }

    //----_sell

    function sellPingEstimateGas(
        uint pongFee,
        address target,
        uint amountIn
    ) public view virtual returns (uint pingFee) {
        uint nonce = sellNonce[_msgSender()];

        pingFee = paramsEstimateGas(
            masterChainId,
            masterContract,
            pongFee,
            _sellPingSignature(nonce+1,target, pongFee, amountIn)
        );
    }

    function _sell(uint pongFee, address from, address to, uint amountIn, uint deadline) internal {
        require(launched, "unlaunched");
        require(amountIn > 0, "amount in err.");
        require(deadline == 0 || deadline > block.timestamp, "deadline err.");
        require(balanceOf(from) >= amountIn, "sell amount exceeds balance");
        uint pingFee = sellPingEstimateGas(pongFee, to, amountIn);
        require(msg.value >= pingFee + pongFee, "bridge fee not enough");

        require(amountIn >= tokenMin, "the amount cannot be too small");

        uint nonce = sellNonce[_msgSender()];

        _burn(from, amountIn);
        paramsEmit2LaunchPad(
            pingFee,
            masterChainId,
            masterContract,
            pongFee,
            _sellPingSignature(nonce+1,to, pongFee, amountIn),
            _msgSender()
        );
        sellNonce[_msgSender()]++;
    }

    //----314token
    function getReserves() public view returns (uint, uint) {
        revert NotImplement();
    }

    function getAmountOut(uint value, bool isBuy) public view returns (uint) {
        revert NotImplement();
    }

    function swapExactETHForTokens(
        uint pongFee,
        address to,
        uint deadline
    ) external payable virtual nonReentrant whenNotPaused{
        _buy(pongFee, to, deadline);
    }

    function swapExactTokensForETH(
        uint pongFee,
        uint amountIn,
        address to,
        uint deadline
    ) external payable virtual nonReentrant whenNotPaused{
        _sell(pongFee, _msgSender(), to, amountIn, deadline);
    }

    receive() external payable {
        //_buy(_msgSender(), block.timestamp);
    }

    function withdrawFee(address to, uint amount) public onlyOwner nonReentrant {
        transferNative(to, amount);
    }

    function slave_cross(uint64 srcChainId, address sender, uint64 dstChainId, address to, uint token,uint nonce) internal virtual override {
        require(!crossNoncePing[srcChainId][sender][nonce], "nonce repetition");
        crossNoncePing[srcChainId][sender][nonce] = true;
        require(dstChainId == block.chainid, "chain id err");
        if (token > 0) _mint(to, token);
        emit Crossed(srcChainId, sender, to, token, nonce);
    }

    function crossToEstimateGas(uint64 dstChainId, address to, uint amount) public view virtual returns (uint pingFee) {
        require(dstChainId == masterChainId, "not master chain");
        uint nonce = crossNonce[dstChainId][to];
        pingFee = paramsEstimateGas(masterChainId, masterContract, 0, _crossPingSignature(nonce+1,dstChainId, to, amount));
    }

    function crossTo(uint64 dstChainId, address to, uint amount) external payable virtual whenNotPaused{
        require(dstChainId == masterChainId, "not master chain");
        address owner = _msgSender();
        require(balanceOf(owner) >= amount, "insufficient balance");
        _burn(owner, amount);
        uint nonce = crossNonce[block.chainid][_msgSender()];
        uint pingFee = crossToEstimateGas(dstChainId, to, amount);
        paramsEmit2LaunchPad(
            pingFee,
            masterChainId,
            masterContract,
            0,
            _crossPingSignature(nonce+1,dstChainId, to, amount),
            _msgSender()
        );
        crossNonce[block.chainid][_msgSender()]++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SlaveTokenBase} from "./lib/SlaveTokenBase.sol";

contract TokenSlave is SlaveTokenBase {
    constructor(
        address _vizingPad,
        uint64 _masterChainId
    ) SlaveTokenBase("EL GATO", "GATO", _vizingPad, address(0), _masterChainId) {}
}