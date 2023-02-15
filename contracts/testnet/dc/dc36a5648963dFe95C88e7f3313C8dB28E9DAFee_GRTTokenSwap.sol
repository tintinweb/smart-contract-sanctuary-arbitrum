// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title GRTTokenSwap
/// @notice A token swap contract that allows exchanging tokens minted by Arbitrum's deprecated GRT contract for the canonical GRT token
/// Note that the inverse swap is not supported
/// @dev This contract needs to be topped off with enough canonical GRT to cover the swaps
contract GRTTokenSwap is Ownable {
    // -- State --

    /// The GRT token contract using the custom GRT gateway
    IERC20 public immutable canonicalGRT;
    /// The GRT token contract using Arbitrum's standard ERC20 gateway
    IERC20 public immutable deprecatedGRT;

    // -- Events --
    event TokensSwapped(address indexed user, uint256 amount);
    event TokensTaken(address indexed owner, address indexed token, uint256 amount);

    // -- Errors --
    /// @dev Cannot swap 0 tokens amounts
    error AmountMustBeGreaterThanZero();
    /// @dev Canonical and deprecated pair addresses are invalid. Either the same or one is 0x00
    error InvalidTokenAddressPair();
    /// @dev The contract does not have enough canonical GRT tokens to cover the swap
    error ContractOutOfFunds();

    // -- Functions --
    /// @notice The constructor for the GRTTokenSwap contract
    constructor(IERC20 _canonicalGRT, IERC20 _deprecatedGRT) {
        if (
            address(_canonicalGRT) == address(0) ||
            address(_deprecatedGRT) == address(0) ||
            address(_canonicalGRT) == address(_deprecatedGRT)
        ) revert InvalidTokenAddressPair();

        canonicalGRT = _canonicalGRT;
        deprecatedGRT = _deprecatedGRT;
    }

    /// @notice Swap the entire balance of the sender's deprecated GRT for canonical GRT
    /// @dev Ensure approve(type(uint256).max) or approve(senderBalance) is called on the deprecated GRT contract before calling this function
    function swapAll() external {
        uint256 balance = deprecatedGRT.balanceOf(msg.sender);
        swap(balance);
    }

    /// @notice Swap deprecated GRT for canonical GRT
    /// @dev Ensure approve(_amount) is called on the deprecated GRT contract before calling this function
    /// @param _amount Amount of tokens to swap
    function swap(uint256 _amount) public {
        if (_amount == 0) revert AmountMustBeGreaterThanZero();

        uint256 contractBalance = canonicalGRT.balanceOf(address(this));
        if (_amount > contractBalance) revert ContractOutOfFunds();

        bool success = deprecatedGRT.transferFrom(msg.sender, address(this), _amount);
        require(success, "Transfer from deprecated GRT failed");
        canonicalGRT.transfer(msg.sender, _amount);

        emit TokensSwapped(msg.sender, _amount);
    }

    /// @notice Transfer all tokens to the contract owner
    /// @dev This is a convenience function to clean up after the contract it's deemed to be no longer necessary
    /// @dev Reverts if either token balance is zero
    function sweep() external onlyOwner {
        (uint256 canonicalBalance, uint256 deprecatedBalance) = getTokenBalances();
        takeCanonical(canonicalBalance);
        takeDeprecated(deprecatedBalance);
    }

    /// @notice Take deprecated tokens from the contract and send it to the owner
    /// @param _amount The amount of tokens to take
    function takeDeprecated(uint256 _amount) public onlyOwner {
        _take(deprecatedGRT, _amount);
    }

    /// @notice Take canonical tokens from the contract and send it to the owner
    /// @param _amount The amount of tokens to take
    function takeCanonical(uint256 _amount) public onlyOwner {
        _take(canonicalGRT, _amount);
    }

    /// @notice Get the token balances
    /// @return canonicalBalance Contract's canonicalGRT balance
    /// @return deprecatedBalance Contract's deprecatedGRT balance
    function getTokenBalances() public view returns (uint256 canonicalBalance, uint256 deprecatedBalance) {
        return (canonicalGRT.balanceOf(address(this)), deprecatedGRT.balanceOf(address(this)));
    }

    /// @notice Take tokens from the contract and send it to the owner
    /// @param _token The token to take
    /// @param _amount The amount of tokens to take
    function _take(IERC20 _token, uint256 _amount) private {
        address owner = owner();
        if (_amount > 0) {
            _token.transfer(owner, _amount);
        }

        emit TokensTaken(owner, address(_token), _amount);
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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