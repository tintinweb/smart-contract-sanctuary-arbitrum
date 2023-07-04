// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SuccinctFeeVault
/// @author Succinct Labs
/// @notice Endpoint for sending fees when using Succinct services.
/// @dev Address(0) is used to represent native currency in places where token address is specified.
contract SuccinctFeeVault is Ownable {
    /// @notice Tracks the amount of active balance that an account has for Succinct services.
    /// @dev balances[token][account] returns the amount of balance for token the account has. To
    ///      check native currency balance, use address(0) as the token address.
    mapping(address => mapping(address => uint256)) public balances;
    /// @notice The allowed senders for the deduct functions.
    mapping(address => bool) public allowedDeductors;

    event Received(address indexed account, address indexed token, uint256 amount);
    event Deducted(address indexed account, address indexed token, uint256 amount);
    event Collected(address indexed to, address indexed token, uint256 amount);

    error InvalidAccount(address account);
    error InvalidToken(address token);
    error InsufficentAllowance(address token, uint256 amount);
    error InsufficientBalance(address token, uint256 amount);
    error FailedToSendNative(uint256 amount);
    error OnlyDeductor(address sender);

    modifier onlyDeductor() {
        if (!allowedDeductors[msg.sender]) {
            revert OnlyDeductor(msg.sender);
        }
        _;
    }

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    /// @notice Add the specified deductor.
    /// @param _deductor The address of the deductor to add.
    function addDeductor(address _deductor) external onlyOwner {
        allowedDeductors[_deductor] = true;
    }

    /// @notice Remove the specified deductor.
    /// @param _deductor The address of the deductor to remove.
    function removeDeductor(address _deductor) external onlyOwner {
        allowedDeductors[_deductor] = false;
    }

    /// @notice Deposit the specified amount of native currency from the caller.
    /// @param _account The account to deposit the native currency to.
    /// @dev The native currency is represented by address(0) in balances.
    function depositNative(address _account) external payable {
        if (_account == address(0)) {
            revert InvalidAccount(_account);
        }

        balances[address(0)][_account] += msg.value;

        emit Received(_account, address(0), msg.value);
    }

    /// @notice Deposit the specified amount of the specified token from the caller.
    /// @param _account The account to deposit the tokens to.
    /// @param _token The address of the token to deposit.
    /// @param _amount The amount of the token to deposit.
    /// @dev MUST approve this contract to spend at least _amount of _token before calling this.
    function deposit(address _account, address _token, uint256 _amount) external {
        if (_account == address(0)) {
            revert InvalidAccount(_account);
        }
        if (_token == address(0)) {
            revert InvalidToken(_token);
        }

        IERC20 token = IERC20(_token);
        uint256 allowance = token.allowance(msg.sender, address(this));
        if (allowance < _amount) {
            revert InsufficentAllowance(_token, _amount);
        }

        token.transferFrom(msg.sender, address(this), _amount);
        balances[_token][_account] += _amount;

        emit Received(_account, _token, _amount);
    }

    /// @notice Deduct the specified amount of native currency from the specified account.
    /// @param _account The account to deduct the native currency from.
    /// @param _amount The amount of native currency to deduct.
    function deductNative(address _account, uint256 _amount) external onlyDeductor {
        if (_account == address(0)) {
            revert InvalidAccount(_account);
        }
        if (balances[address(0)][_account] < _amount) {
            revert InsufficientBalance(address(0), _amount);
        }

        balances[address(0)][_account] -= _amount;

        emit Deducted(_account, address(0), _amount);
    }

    /// @notice Deduct the specified amount of the specified token from the specified account.
    /// @param _account The account to deduct the tokens from.
    /// @param _token The address of the token to deduct.
    /// @param _amount The amount of the token to deduct.
    function deduct(address _account, address _token, uint256 _amount) external onlyDeductor {
        if (_account == address(0)) {
            revert InvalidAccount(_account);
        }
        if (_token == address(0)) {
            revert InvalidToken(_token);
        }
        if (balances[_token][_account] < _amount) {
            revert InsufficientBalance(_token, _amount);
        }

        balances[_token][_account] -= _amount;

        emit Deducted(_account, _token, _amount);
    }

    /// @notice Collect the specified amount of native currency.
    /// @param _to The address to send the collected native currency to.
    /// @param _amount The amount of native currency to collect.
    function collectNative(address _to, uint256 _amount) external onlyOwner {
        if (address(this).balance < _amount) {
            revert InsufficientBalance(address(0), _amount);
        }

        (bool success,) = _to.call{value: _amount}("");
        if (!success) {
            revert FailedToSendNative(_amount);
        }

        emit Collected(_to, address(0), _amount);
    }

    /// @notice Collect the specified amount of the specified token.
    /// @param _to The address to send the collected tokens to.
    /// @param _token The address of the token to collect.
    /// @param _amount The amount of the token to collect.
    function collect(address _to, address _token, uint256 _amount) external onlyOwner {
        if (_token == address(0)) {
            revert InvalidToken(_token);
        }
        if (IERC20(_token).balanceOf(address(this)) < _amount) {
            revert InsufficientBalance(_token, _amount);
        }

        IERC20(_token).transfer(_to, _amount);

        emit Collected(_to, _token, _amount);
    }
}

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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