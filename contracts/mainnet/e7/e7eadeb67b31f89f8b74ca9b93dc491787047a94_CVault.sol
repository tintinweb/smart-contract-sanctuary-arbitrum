/**
 *Submitted for verification at Arbiscan.io on 2024-05-16
*/

// Sources flattened with hardhat v2.19.4 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity 0.8.25;

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

// File @openzeppelin/contracts/access/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
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

// File @openzeppelin/contracts/security/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
    require(!paused(), 'Pausable: paused');
  }

  /**
   * @dev Throws if the contract is not paused.
   */
  function _requirePaused() internal view virtual {
    require(paused(), 'Pausable: not paused');
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

// File @openzeppelin/contracts/security/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
    require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');

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

// File @openzeppelin/contracts/token/ERC20/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

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

// File contracts/CVault.sol

// Original license: SPDX_License_Identifier: MIT

/**
 * @title CVault - Codyfight Wallet Contract
 * @dev The CVault contract serves as a non-custodial wallet for Codyfight players to manage their CTOK tokens.
 * @notice Players can deposit and withdraw CTOK tokens from their wallet.
 * @notice This Allows players to interact with the Codyfight game without needing to pay gas fees for each transaction.
 */
contract CVault is Ownable, Pausable, ReentrancyGuard {
  // *** State variables ***

  /**
   * @dev The Codyfight API URL.
   * @notice This URL is used to confirm the contract's veracity.
   * @notice The URL is hardcoded and cannot be changed after deployment.
   */
  string public constant api = 'https://blockchain.codyfight.com/contracts';

  /**
   * @dev The name of the contract.
   */
  string public constant name = 'Codyfight Vault';

  /**
   * @dev The CTOK token contract address and interface. It cannot be changed after deployment.
   * @notice The CTOK token contract is used to deposit and withdraw CTOK tokens.
   */
  IERC20 public immutable token;

  // *** Events ***

  /**
   * @dev Emitted when a player deposits CTOK tokens into their balance.
   * @param from The address of the sender.
   * @param to The address of the recipient.
   * @param id The ID of the CLayer main account.
   * @param amount The amount of CTOK tokens deposited.
   */
  event Deposit(
    address indexed from,
    address indexed to,
    uint256 indexed id,
    uint256 amount
  );

  /**
   * @dev Emitted when a player withdraws CTOK tokens from their balance.
   * @param from The address of the sender.
   * @param to The address of the recipient.
   * @param id The ID of the CLayer main account.
   * @param amount The amount of CTOK tokens withdrawn.
   */
  event Withdraw(
    address indexed from,
    address indexed to,
    uint256 indexed id,
    uint256 amount
  );

  // *** Constructor ***

  /**
   * @dev Constructor to initialize the contract.
   * @param _owner The address of the contract owner.
   * @param _token The address of the CTOK token contract.
   */
  constructor(address _owner, address _token) {
    require(_owner != address(0), 'CVault: Owner address cannot be zero.');
    require(_token != address(0), 'CVault: Token address cannot be zero.');

    token = IERC20(_token);
    transferOwnership(_owner);
  }

  receive() external payable {
    revert('CVault: CTOK Deposits can only be made through Codyfight website');
  }

  // *** Transactions ***

  /**
   * @dev Allows the contract to transfer CTOK tokens from the player's wallet to the contract.
   * @notice This function is useful for depositing CTOK tokens into the contract, without requiring the player to pay gas fees.
   * @param sender The address of the sender. The player who will deposit the CTOK tokens.
   * @param id The ID of the CLayer main account.
   * @param amount The amount of CTOK tokens to deposit.
   */
  function deposit(
    address sender,
    uint256 id,
    uint256 amount
  ) external nonReentrant whenNotPaused onlyOwner {
    require(id >= 0, 'CVault: invalid ID');
    require(amount > 0, 'CVault: amount must be greater than 0');
    require(sender != address(0), 'CVault: invalid sender address');

    require(
      token.transferFrom(sender, address(this), amount),
      'CVault: transfer failed'
    );

    emit Deposit(sender, address(this), id, amount);
  }

  /**
   * @dev Allows the contract to transfer CTOK tokens from the contract to the player's wallet.
   * @notice This function is useful for transferring CTOK tokens from the contract to the player's wallet, without requiring them to pay gas fees.
   * @param recipient The address of the recipient. The player who will receive the CTOK tokens.
   * @param id The ID of the CLayer main account.
   * @param amount The amount of CTOK tokens to withdraw.
   */
  function withdraw(
    address recipient,
    uint256 id,
    uint256 amount
  ) external nonReentrant whenNotPaused onlyOwner {
    require(id >= 0, 'CVault: invalid ID');
    require(amount > 0, 'CVault: amount must be greater than 0');
    require(recipient != address(0), 'CVault: invalid recipient address');

    require(token.transfer(recipient, amount), 'CVault: transfer failed');

    emit Withdraw(address(this), recipient, id, amount);
  }

  // *** Control functions ***

  /**
   * @dev Allows the contract owner to pause contract operations.
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @dev Allows the contract owner to unpause contract operations.
   */
  function unpause() external onlyOwner {
    _unpause();
  }
}