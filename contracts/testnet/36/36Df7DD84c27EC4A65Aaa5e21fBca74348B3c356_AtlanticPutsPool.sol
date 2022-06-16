/**
 *Submitted for verification at Arbiscan on 2022-06-15
*/

// Sources flattened with hardhat v2.9.6 https://hardhat.org

// File contracts/interfaces/IERC20.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * NOTE: Modified to include symbols and decimals.
 */
interface IERC20 {
  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

// File @openzeppelin/contracts/utils/math/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      uint256 c = a + b;
      if (c < a) return (false, 0);
      return (true, c);
    }
  }

  /**
   * @dev Returns the substraction of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b > a) return (false, 0);
      return (true, a - b);
    }
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
      // benefit is lost if 'b' is also tested.
      // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
      if (a == 0) return (true, 0);
      uint256 c = a * b;
      if (c / a != b) return (false, 0);
      return (true, c);
    }
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a / b);
    }
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
      if (b == 0) return (false, 0);
      return (true, a % b);
    }
  }

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
    return a + b;
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
    return a - b;
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
    return a * b;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator.
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting when dividing by zero.
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
    return a % b;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {trySub}.
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
    unchecked {
      require(b <= a, errorMessage);
      return a - b;
    }
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    unchecked {
      require(b > 0, errorMessage);
      return a / b;
    }
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting with custom message when dividing by zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryMod}.
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
    unchecked {
      require(b > 0, errorMessage);
      return a % b;
    }
  }
}

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{ value: amount }("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain `call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{ value: value }(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return
      functionDelegateCall(
        target,
        data,
        "Address: low-level delegate call failed"
      );
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
   * revert reason using the provided one.
   *
   * _Available since v4.3._
   */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// File contracts/libraries/SafeERC20.sol

pragma solidity ^0.8.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    // solhint-disable-next-line max-line-length
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(
      value,
      "SafeERC20: decreased allowance below zero"
    );
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(
      data,
      "SafeERC20: low-level call failed"
    );
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(
        abi.decode(returndata, (bool)),
        "SafeERC20: ERC20 operation did not succeed"
      );
    }
  }
}

// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }
}

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view virtual returns (bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    require(!paused(), "Pausable: paused");
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
    require(paused(), "Pausable: not paused");
    _;
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

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File contracts/helper/ContractWhitelist.sol

pragma solidity ^0.8.0;

/// @title ContractWhitelist
/// @author witherblock
/// @notice A helper contract that lets you add a list of whitelisted contracts that should be able to interact with restricited functions
abstract contract ContractWhitelist is Ownable {
  /// @dev contract => whitelisted or not
  mapping(address => bool) public whitelistedContracts;

  /*==== SETTERS ====*/

  /// @dev add to the contract whitelist
  /// @param _contract the address of the contract to add to the contract whitelist
  /// @return whether the contract was successfully added to the whitelist
  function addToContractWhitelist(address _contract)
    external
    onlyOwner
    returns (bool)
  {
    require(
      isContract(_contract),
      "ContractWhitelist: Address must be a contract address"
    );
    require(
      !whitelistedContracts[_contract],
      "ContractWhitelist: Contract already whitelisted"
    );

    whitelistedContracts[_contract] = true;

    emit AddToContractWhitelist(_contract);

    return true;
  }

  /// @dev remove from  the contract whitelist
  /// @param _contract the address of the contract to remove from the contract whitelist
  /// @return whether the contract was successfully removed from the whitelist
  function removeFromContractWhitelist(address _contract)
    external
    returns (bool)
  {
    require(
      whitelistedContracts[_contract],
      "ContractWhitelist: Contract not whitelisted"
    );

    whitelistedContracts[_contract] = false;

    emit RemoveFromContractWhitelist(_contract);

    return true;
  }

  /* ========== MODIFIERS ========== */

  // Modifier is eligible sender modifier
  modifier isEligibleSender() {
    if (isContract(msg.sender))
      require(
        whitelistedContracts[msg.sender],
        "ContractWhitelist: Contract must be whitelisted"
      );
    _;
  }

  /*==== VIEWS ====*/

  /// @dev checks for contract or eoa addresses
  /// @param addr the address to check
  /// @return whether the passed address is a contract address
  function isContract(address addr) public view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }

  /*==== EVENTS ====*/

  event AddToContractWhitelist(address indexed _contract);

  event RemoveFromContractWhitelist(address indexed _contract);
}

// File solidity-linked-list/contracts/[email protected]

pragma solidity ^0.8.0;

interface IStructureInterface {
  function getValue(uint256 _id) external view returns (uint256);
}

/**
 * @title StructuredLinkedList
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev An utility library for using sorted linked list data structures in your Solidity project.
 */
library StructuredLinkedList {
  uint256 private constant _NULL = 0;
  uint256 private constant _HEAD = 0;

  bool private constant _PREV = false;
  bool private constant _NEXT = true;

  struct List {
    uint256 size;
    mapping(uint256 => mapping(bool => uint256)) list;
  }

  /**
   * @dev Checks if the list exists
   * @param self stored linked list from contract
   * @return bool true if list exists, false otherwise
   */
  function listExists(List storage self) internal view returns (bool) {
    // if the head nodes previous or next pointers both point to itself, then there are no items in the list
    if (self.list[_HEAD][_PREV] != _HEAD || self.list[_HEAD][_NEXT] != _HEAD) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Checks if the node exists
   * @param self stored linked list from contract
   * @param _node a node to search for
   * @return bool true if node exists, false otherwise
   */
  function nodeExists(List storage self, uint256 _node)
    internal
    view
    returns (bool)
  {
    if (self.list[_node][_PREV] == _HEAD && self.list[_node][_NEXT] == _HEAD) {
      if (self.list[_HEAD][_NEXT] == _node) {
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Returns the number of elements in the list
   * @param self stored linked list from contract
   * @return uint256
   */
  function sizeOf(List storage self) internal view returns (uint256) {
    return self.size;
  }

  /**
   * @dev Returns the links of a node as a tuple
   * @param self stored linked list from contract
   * @param _node id of the node to get
   * @return bool, uint256, uint256 true if node exists or false otherwise, previous node, next node
   */
  function getNode(List storage self, uint256 _node)
    internal
    view
    returns (
      bool,
      uint256,
      uint256
    )
  {
    if (!nodeExists(self, _node)) {
      return (false, 0, 0);
    } else {
      return (true, self.list[_node][_PREV], self.list[_node][_NEXT]);
    }
  }

  /**
   * @dev Returns the link of a node `_node` in direction `_direction`.
   * @param self stored linked list from contract
   * @param _node id of the node to step from
   * @param _direction direction to step in
   * @return bool, uint256 true if node exists or false otherwise, node in _direction
   */
  function getAdjacent(
    List storage self,
    uint256 _node,
    bool _direction
  ) internal view returns (bool, uint256) {
    if (!nodeExists(self, _node)) {
      return (false, 0);
    } else {
      return (true, self.list[_node][_direction]);
    }
  }

  /**
   * @dev Returns the link of a node `_node` in direction `_NEXT`.
   * @param self stored linked list from contract
   * @param _node id of the node to step from
   * @return bool, uint256 true if node exists or false otherwise, next node
   */
  function getNextNode(List storage self, uint256 _node)
    internal
    view
    returns (bool, uint256)
  {
    return getAdjacent(self, _node, _NEXT);
  }

  /**
   * @dev Returns the link of a node `_node` in direction `_PREV`.
   * @param self stored linked list from contract
   * @param _node id of the node to step from
   * @return bool, uint256 true if node exists or false otherwise, previous node
   */
  function getPreviousNode(List storage self, uint256 _node)
    internal
    view
    returns (bool, uint256)
  {
    return getAdjacent(self, _node, _PREV);
  }

  /**
   * @dev Can be used before `insert` to build an ordered list.
   * @dev Get the node and then `insertBefore` or `insertAfter` basing on your list order.
   * @dev If you want to order basing on other than `structure.getValue()` override this function
   * @param self stored linked list from contract
   * @param _structure the structure instance
   * @param _value value to seek
   * @return uint256 next node with a value less than _value
   */
  function getSortedSpot(
    List storage self,
    address _structure,
    uint256 _value
  ) internal view returns (uint256) {
    if (sizeOf(self) == 0) {
      return 0;
    }

    uint256 next;
    (, next) = getAdjacent(self, _HEAD, _NEXT);
    while (
      (next != 0) &&
      ((_value < IStructureInterface(_structure).getValue(next)) != _NEXT)
    ) {
      next = self.list[next][_NEXT];
    }
    return next;
  }

  /**
   * @dev Insert node `_new` beside existing node `_node` in direction `_NEXT`.
   * @param self stored linked list from contract
   * @param _node existing node
   * @param _new  new node to insert
   * @return bool true if success, false otherwise
   */
  function insertAfter(
    List storage self,
    uint256 _node,
    uint256 _new
  ) internal returns (bool) {
    return _insert(self, _node, _new, _NEXT);
  }

  /**
   * @dev Insert node `_new` beside existing node `_node` in direction `_PREV`.
   * @param self stored linked list from contract
   * @param _node existing node
   * @param _new  new node to insert
   * @return bool true if success, false otherwise
   */
  function insertBefore(
    List storage self,
    uint256 _node,
    uint256 _new
  ) internal returns (bool) {
    return _insert(self, _node, _new, _PREV);
  }

  /**
   * @dev Removes an entry from the linked list
   * @param self stored linked list from contract
   * @param _node node to remove from the list
   * @return uint256 the removed node
   */
  function remove(List storage self, uint256 _node) internal returns (uint256) {
    if ((_node == _NULL) || (!nodeExists(self, _node))) {
      return 0;
    }
    _createLink(self, self.list[_node][_PREV], self.list[_node][_NEXT], _NEXT);
    delete self.list[_node][_PREV];
    delete self.list[_node][_NEXT];

    self.size -= 1; // NOT: SafeMath library should be used here to decrement.

    return _node;
  }

  /**
   * @dev Pushes an entry to the head of the linked list
   * @param self stored linked list from contract
   * @param _node new entry to push to the head
   * @return bool true if success, false otherwise
   */
  function pushFront(List storage self, uint256 _node) internal returns (bool) {
    return _push(self, _node, _NEXT);
  }

  /**
   * @dev Pushes an entry to the tail of the linked list
   * @param self stored linked list from contract
   * @param _node new entry to push to the tail
   * @return bool true if success, false otherwise
   */
  function pushBack(List storage self, uint256 _node) internal returns (bool) {
    return _push(self, _node, _PREV);
  }

  /**
   * @dev Pops the first entry from the head of the linked list
   * @param self stored linked list from contract
   * @return uint256 the removed node
   */
  function popFront(List storage self) internal returns (uint256) {
    return _pop(self, _NEXT);
  }

  /**
   * @dev Pops the first entry from the tail of the linked list
   * @param self stored linked list from contract
   * @return uint256 the removed node
   */
  function popBack(List storage self) internal returns (uint256) {
    return _pop(self, _PREV);
  }

  /**
   * @dev Pushes an entry to the head of the linked list
   * @param self stored linked list from contract
   * @param _node new entry to push to the head
   * @param _direction push to the head (_NEXT) or tail (_PREV)
   * @return bool true if success, false otherwise
   */
  function _push(
    List storage self,
    uint256 _node,
    bool _direction
  ) private returns (bool) {
    return _insert(self, _HEAD, _node, _direction);
  }

  /**
   * @dev Pops the first entry from the linked list
   * @param self stored linked list from contract
   * @param _direction pop from the head (_NEXT) or the tail (_PREV)
   * @return uint256 the removed node
   */
  function _pop(List storage self, bool _direction) private returns (uint256) {
    uint256 adj;
    (, adj) = getAdjacent(self, _HEAD, _direction);
    return remove(self, adj);
  }

  /**
   * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
   * @param self stored linked list from contract
   * @param _node existing node
   * @param _new  new node to insert
   * @param _direction direction to insert node in
   * @return bool true if success, false otherwise
   */
  function _insert(
    List storage self,
    uint256 _node,
    uint256 _new,
    bool _direction
  ) private returns (bool) {
    if (!nodeExists(self, _new) && nodeExists(self, _node)) {
      uint256 c = self.list[_node][_direction];
      _createLink(self, _node, _new, _direction);
      _createLink(self, _new, c, _direction);

      self.size += 1; // NOT: SafeMath library should be used here to increment.

      return true;
    }

    return false;
  }

  /**
   * @dev Creates a bidirectional link between two nodes on direction `_direction`
   * @param self stored linked list from contract
   * @param _node existing node
   * @param _link node to link to in the _direction
   * @param _direction direction to insert node in
   */
  function _createLink(
    List storage self,
    uint256 _node,
    uint256 _link,
    bool _direction
  ) private {
    self.list[_link][!_direction] = _node;
    self.list[_node][_direction] = _link;
  }
}

// File contracts/interfaces/IOptionPricing.sol

pragma solidity ^0.8.0;

interface IOptionPricing {
  function getOptionPrice(
    bool isPut,
    uint256 expiry,
    uint256 strike,
    uint256 lastPrice,
    uint256 baseIv
  ) external view returns (uint256);
}

// File contracts/fees/IFeeStrategy.sol

pragma solidity ^0.8.0;

interface IFeeStrategy {
  function calculatePurchaseFees(
    uint256,
    uint256,
    uint256
  ) external view returns (uint256);

  function calculateSettlementFees(
    uint256,
    uint256,
    uint256
  ) external view returns (uint256);
}

// File contracts/atlantic-pools/AtlanticPutsPool.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**                                                                                                 
          █████╗ ████████╗██╗      █████╗ ███╗   ██╗████████╗██╗ ██████╗
          ██╔══██╗╚══██╔══╝██║     ██╔══██╗████╗  ██║╚══██╔══╝██║██╔════╝
          ███████║   ██║   ██║     ███████║██╔██╗ ██║   ██║   ██║██║     
          ██╔══██║   ██║   ██║     ██╔══██║██║╚██╗██║   ██║   ██║██║     
          ██║  ██║   ██║   ███████╗██║  ██║██║ ╚████║   ██║   ██║╚██████╗
          ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝ ╚═════╝
                                                                        
          ██████╗ ██████╗ ████████╗██╗ ██████╗ ███╗   ██╗███████╗       
          ██╔═══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝       
          ██║   ██║██████╔╝   ██║   ██║██║   ██║██╔██╗ ██║███████╗       
          ██║   ██║██╔═══╝    ██║   ██║██║   ██║██║╚██╗██║╚════██║       
          ╚██████╔╝██║        ██║   ██║╚██████╔╝██║ ╚████║███████║       
          ╚═════╝ ╚═╝        ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝       
                                                               
                            Atlantic Call Options
              Yield bearing put options with mobile collateral                                                           
*/

interface IPriceOracle {
  function latestAnswer() external view returns (int256);
}

interface IVolatilityOracle {
  function getVolatility(uint256) external view returns (uint256);
}

contract AtlanticPutsPool is Pausable, ReentrancyGuard, ContractWhitelist {
  using SafeERC20 for IERC20;
  using StructuredLinkedList for StructuredLinkedList.List;

  struct Deposit {
    // Deposit strike
    uint256 strike;
    // Deposit timestamp
    uint256 timestamp;
    // Liquidity deposited
    uint256 liquidity;
    // Premium distribution ratio at the instance of deposit
    uint256 premiumDistributionRatio;
    // Funding distribution ratio at the instance of deposit
    uint256 fundingDistributionRatio;
    // underlying distribution ratio at the instance of deposit
    uint256 underlyingDistributionRatio;
    // Address of the depositor
    address depositor;
  }

  struct Address {
    address quoteToken;
    address baseToken;
    address feeDistributor;
    address feeStrategy;
    address optionPricing;
    address priceOracle;
    address volatilityOracle;
    address governance;
  }

  struct MaxStrikesCollateral {
    address user;
    uint256 optionStrike;
    uint256 optionsAmount;
    uint256[] maxStrikes;
    uint256[] weights;
    CollateralUnlock collateralUnlock;
  }

  struct CollateralUnlock {
    uint256 fundingRate;
    uint256 expiryDelta;
    uint256 collateralAccess;
  }

  struct Checkpoint {
    uint256 premiumCollected;
    uint256 fundingCollected;
    uint256 underlyingCollected;
    // Amount of liquidity
    uint256 liquidity;
    // Amount of liquidity balance (-PnL,-Refund)
    uint256 liquidityBalance;
    uint256 activeCollateral;
    uint256 unlockedCollateral;
    uint256 refund;
    uint256 premiumDistributionRatio;
    uint256 fundingDistributionRatio;
    uint256 underlyingDistributionRatio;
  }

  struct VaultState {
    uint256 totalEpochUnlockedCollateral;
    uint256 totalEpochActiveCollateral;
    uint256[2] maxStrikeRange;
    uint256 settlementPrice;
    uint256 expiryTime;
    uint256 startTime;
    bool isVaultReady;
    bool isVaultExpired;
  }

  struct VaultConfiguration {
    uint256 collateralUtilizationWeight;
    uint256 tickSize;
    uint256 baseFundingRate;
    uint256 unwindFee;
    uint256 expireDelayTolerance;
  }

  uint256 public currentEpoch;

  mapping(uint256 => VaultState) public epochVaultStates;

  VaultConfiguration public vaultConfiguration;

  /// @notice Checkpoints count for an epoch and maxstrike
  /// @dev epoch => maxStrike => checkpoint
  mapping(uint256 => mapping(uint256 => uint256))
    public maxStrikeCheckpointsCount;

  /// @notice Checkpoints array that stores all the checkpoints
  /// @dev epoch => checpoint count => Checkpoint
  mapping(uint256 => mapping(uint256 => mapping(uint256 => Checkpoint)))
    public checkpoints;

  /// @notice Mapping of collateral used from max strikes
  /// @dev keusery => indexes
  mapping(uint256 => mapping(address => uint256[]))
    public userMaxStrikesCollaterals;

  /// @notice Array of all user max strikes collaterals;
  /// @dev epoch => MaxStrikesCollateral[]
  mapping(uint256 => MaxStrikesCollateral[]) private maxStrikesCollaterals;

  /// @notice Addresses this contract uses
  Address public addresses;

  /// @notice Structured linked list for max strikes
  /// @dev epoch => strike list
  mapping(uint256 => StructuredLinkedList.List) private epochStrikesList;

  /// @notice Mapping of max strikes to MaxStrike struct
  /// @dev epoch => strike/node => MaxStrike
  mapping(uint256 => mapping(uint256 => bool)) private isValidStrike;

  // (Max strike => (user => depositsForMaxStrikes index))
  mapping(uint256 => mapping(address => uint256[])) private userEpochDeposits;

  /// @dev (epoch => Deposit[])
  mapping(uint256 => Deposit[]) public epochDeposits;

  /// @notice  Puts for written for strikes by this max strike in 1e18 decimals
  mapping(uint256 => mapping(uint256 => bool)) public strikesWritten;

  /// @notice Mapping to keep track of managed contracts
  /// @dev Contract => is managed contract?
  mapping(address => bool) public managedContracts;

  mapping(address => uint256) private tokenBalances;

  /*==== EVENTS ====*/

  event ExpireDelayToleranceUpdate(uint256 expireDelayTolerance);

  event EmergencyWithdraw(address sender);

  event Bootstrap(uint256 epoch);

  event Unwind(
    uint256 indexed epoch,
    uint256 indexed strike,
    uint256 amount,
    address caller
  );

  event NewDeposit(
    uint256 indexed epoch,
    uint256 indexed strike,
    uint256 amount,
    address indexed user,
    address sender
  );

  event NewPurchase(
    uint256 indexed epoch,
    uint256 indexed strike,
    uint256 amount,
    uint256 premium,
    uint256 fee,
    address indexed user,
    address sender
  );

  event NewSettle(
    uint256 indexed epoch,
    uint256 indexed strike,
    address indexed user,
    uint256 amount,
    uint256 pnl
  );

  event NewWithdraw(
    uint256 indexed epoch,
    uint256 indexed strike,
    address indexed user,
    uint256 withdrawableAmount,
    uint256 funding,
    uint256 premium,
    uint256 underlying
  );

  event UnlockCollateral(
    uint256 indexed epoch,
    uint256 indexed strike,
    uint256 totalCollateral,
    address caller
  );

  event RelockCollateral(
    uint256 indexed epoch,
    uint256 indexed strike,
    uint256 totalCollateral,
    address caller
  );

  event EpochExpired(address sender, uint256 settlementPrice);

  /*==== Error ====*/

  error AtlanticPutsPoolError(uint256 errorCode);

  /*==== CONSTRUCTOR ====*/

  constructor(
    Address memory _addresses,
    VaultConfiguration memory _vaultConfiguration
  ) {
    addresses = _addresses;
    vaultConfiguration = _vaultConfiguration;
  }

  /// @notice Add a managed contract
  /// @param _managedContract Address of the managed contract
  function addManagedContract(address _managedContract) external onlyOwner {
    managedContracts[_managedContract] = true;
  }

  /// @notice Sets the current epoch as expired.
  function expireEpoch() external whenNotPaused isEligibleSender nonReentrant {
    _validate(!epochVaultStates[currentEpoch].isVaultExpired, 3);
    uint256 epochExpiry = epochVaultStates[currentEpoch].expiryTime;
    _validate((block.timestamp >= epochExpiry), 4);
    _validate(
      block.timestamp <= epochExpiry + vaultConfiguration.expireDelayTolerance,
      5
    );
    epochVaultStates[currentEpoch].settlementPrice = getUsdPrice();
    epochVaultStates[currentEpoch].isVaultExpired = true;

    _expireEpoch();
    emit EpochExpired(msg.sender, getUsdPrice());
  }

  /// @notice Sets the current epoch as expired. Only can be called by governance.
  /// @param settlementPrice The settlement price
  function expireEpoch(uint256 settlementPrice)
    external
    onlyGovernance
    whenNotPaused
  {
    uint256 epoch = currentEpoch;
    _validate(!epochVaultStates[epoch].isVaultExpired, 3);
    _validate(
      (block.timestamp >
        epochVaultStates[epoch].expiryTime +
          vaultConfiguration.expireDelayTolerance),
      5
    );
    epochVaultStates[epoch].settlementPrice = settlementPrice;
    epochVaultStates[epoch].isVaultExpired = true;
    _expireEpoch();

    emit EpochExpired(msg.sender, settlementPrice);
  }

  /*==== SETTER METHODS ====*/

  function setVaultConfiguration(VaultConfiguration calldata _vaultConfig)
    external
    onlyOwner
  {
    vaultConfiguration = _vaultConfig;
  }

  /// @notice Pauses the vault for emergency cases
  /// @dev Can only be called by governance
  /// @return Whether it was successfully paused
  function pause() external onlyGovernance returns (bool) {
    _pause();
    _expireEpoch();
    return true;
  }

  /// @notice Unpauses the vault
  /// @dev Can only be called by governance
  /// @return Whether it was successfully unpaused
  function unpause() external onlyGovernance returns (bool) {
    _unpause();
    return true;
  }

  /// @notice Sets (adds) a list of addresses to the address list
  /// @param _addresses New addresses using Address struct
  function setAddresses(Address calldata _addresses)
    public
    onlyOwner
    returns (bool)
  {
    addresses = _addresses;
    return true;
  }

  // /*==== METHODS ====*/

  /// @notice Transfers all funds to msg.sender
  /// @dev Can only be called by governance
  /// @param tokens The list of erc20 tokens to withdraw
  /// @param transferNative Whether should transfer the native currency
  function emergencyWithdraw(address[] calldata tokens, bool transferNative)
    external
    onlyOwner
    whenPaused
    returns (bool)
  {
    if (transferNative) payable(msg.sender).transfer(address(this).balance);

    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20 token = IERC20(tokens[i]);
      token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    emit EmergencyWithdraw(msg.sender);

    return true;
  }

  /**
   * @notice Deposits USD into the ssov-p to mint puts in the next epoch for selected strikes
   * @param maxStrike Exact price of strike in 1e8 decimals
   * @param liquidity Amount of liquidity to provide in 1e6 decimals
   * @param user Address of the user to deposit for
   */
  function deposit(
    uint256 maxStrike,
    uint256 liquidity,
    address user
  ) external whenNotPaused isEligibleSender {
    // Check if maxStrike is less than current price of base asset
    _validate(maxStrike <= getUsdPrice(), 8);

    uint256 epoch = currentEpoch;
    _validate(_isVaultReady(epoch), 17);

    // Check if liquidity > 0
    _validate(liquidity > 0, 9);

    _validate(_isValidMaxStrike(maxStrike), 11);

    // New funding and premium ratio calculates
    (
      uint256 premiumRatio,
      uint256 fundingRatio,
      uint256 underlyingRatio
    ) = onUpdateCheckpoint(epoch, maxStrike);

    // Add to deposits for `maxStrike`
    epochDeposits[epoch].push(
      Deposit(
        maxStrike,
        block.timestamp,
        liquidity,
        premiumRatio,
        fundingRatio,
        underlyingRatio,
        user
      )
    );

    // Update checkpoint
    _updateCheckpoint(
      epoch,
      maxStrike,
      liquidity,
      liquidity,
      premiumRatio,
      fundingRatio,
      underlyingRatio
    );

    // Transfer quote/deposit token from user
    IERC20(addresses.quoteToken).safeTransferFrom(
      msg.sender,
      address(this),
      liquidity
    );

    tokenBalances[addresses.quoteToken] += liquidity;

    // Add `maxStrike` if it doesn't exist
    if (!isValidStrike[epoch][maxStrike]) _addMaxStrike(maxStrike, epoch);

    // Add index of deposit to user deposits
    userEpochDeposits[maxStrike][user].push(epochDeposits[epoch].length - 1);

    // Emit event
    emit NewDeposit(epoch, maxStrike, liquidity, user, msg.sender);
  }

  function _isValidMaxStrike(uint256 maxStrike) private view returns (bool) {
    return maxStrike > 0 && maxStrike % vaultConfiguration.tickSize == 0;
  }

  /**
   * @notice Purchases puts for the current epoch
   * @param strike Strike index for current epoch
   * @param amount Amount of puts to purchase
   */
  function purchase(
    uint256 strike,
    uint256 amount,
    address user
  ) external whenNotPaused isEligibleSender returns (uint256, uint256) {
    _isManagedContract();
    _validate(amount > 0, 12);

    uint256 epoch = currentEpoch;

    _validate(_isValidMaxStrike(strike), 11);
    _validate(_isVaultReady(epoch), 17);
    _validate(strike <= epochVaultStates[epoch].maxStrikeRange[0], 8);

    // Calculate liquidity required
    uint256 collateralRequired = (strike * amount) / 1e20;

    // Should have adequate cumulative liquidity
    _validate(getCumulativeLiquidity(epoch) >= collateralRequired, 13);

    epochVaultStates[epoch].totalEpochActiveCollateral += collateralRequired;

    // Price/premium of option
    uint256 premium = calculatePremium(strike, amount);

    // Fees on top of premium for fee distributor
    uint256 fees = calculatePurchaseFees(strike, amount);

    uint256 index;
    (index, amount) = _purchase(
      strike,
      epoch,
      premium,
      collateralRequired,
      user
    );

    _validate(_transferIn(addresses.quoteToken) == (premium + fees), 33);

    _transferOut(addresses.quoteToken, addresses.feeDistributor, fees);

    emit NewPurchase(epoch, strike, amount, premium, fees, user, msg.sender);

    return (index, amount);
  }

  /**
   * @notice Settle calculates the PnL for the user and withdraws the PnL in the quote token to the user. Will also the burn the option tokens from the user.
   * @param maxStrikesCollateralIndex user's MaxStrikeCollateral index
   * @param epoch epoch in which option was purchased in
   * @return pnl
   */
  function settle(
    uint256 maxStrikesCollateralIndex,
    uint256 epoch,
    address receiver
  ) external whenNotPaused isEligibleSender returns (uint256 pnl) {
    _isManagedContract();

    MaxStrikesCollateral memory _maxStrikeCollateral = maxStrikesCollaterals[
      epoch
    ][userMaxStrikesCollaterals[epoch][msg.sender][maxStrikesCollateralIndex]];

    _validate(_maxStrikeCollateral.user != address(0), 31);
    _validate(_maxStrikeCollateral.collateralUnlock.expiryDelta == 0, 29);

    uint256 expiry = epochVaultStates[epoch].expiryTime;

    _validate(
      block.timestamp >= (expiry - 1 hours) && block.timestamp <= expiry,
      33
    );

    uint256 settlementPrice = epochVaultStates[epoch].expiryTime <=
      block.timestamp
      ? epochVaultStates[epoch].settlementPrice
      : getUsdPrice();

    pnl = calculatePnl(
      settlementPrice,
      _maxStrikeCollateral.optionStrike,
      _maxStrikeCollateral.optionsAmount
    );

    _validate(pnl > 0, 15);

    for (uint256 i = 0; i < _maxStrikeCollateral.maxStrikes.length; ) {
      checkpoints[epoch][_maxStrikeCollateral.maxStrikes[i]][
        maxStrikeCheckpointsCount[epoch][_maxStrikeCollateral.maxStrikes[i]]
      ].liquidityBalance -= (pnl * _maxStrikeCollateral.weights[i]) / 1e18;

      unchecked {
        ++i;
      }
    }

    // Total fee charged
    uint256 totalFee = calculateSettlementFees(
      settlementPrice,
      pnl,
      _maxStrikeCollateral.optionsAmount
    );

    IERC20 settlementToken = IERC20(addresses.quoteToken);

    // Transfer PnL to user
    settlementToken.safeTransfer(receiver, pnl - totalFee);

    // Transfer PnL to user
    settlementToken.safeTransfer(addresses.feeDistributor, totalFee);

    _updateTokenBalance(address(settlementToken));

    delete maxStrikesCollaterals[epoch][
      userMaxStrikesCollaterals[epoch][msg.sender][maxStrikesCollateralIndex]
    ];

    // Emit event
    emit NewSettle(
      epoch,
      _maxStrikeCollateral.optionStrike,
      msg.sender,
      _maxStrikeCollateral.optionsAmount,
      pnl - totalFee
    );
  }

  /**
   * @notice Gracefully exercises an atlantic, sends collateral to integrated protocol,
   * underlying to writer and charges an unwind fee as well as remaining funding fees
   * to the option holder/protocol
   * @param maxStrikesCollateralIndex Index in maxStrikesCollateral[]
   */
  function unwind(uint256 maxStrikesCollateralIndex)
    external
    whenNotPaused
    returns (uint256 unwindAmount)
  {
    _isManagedContract();
    uint256 epoch = currentEpoch;

    _validate(_isVaultReady(epoch), 17);

    MaxStrikesCollateral memory _maxStrikeCollateral = maxStrikesCollaterals[
      epoch
    ][userMaxStrikesCollaterals[epoch][msg.sender][maxStrikesCollateralIndex]];

    _validate(_maxStrikeCollateral.user != address(0), 28);
    _validate(_maxStrikeCollateral.collateralUnlock.expiryDelta != 0, 29);

    uint256 unwindFees = calculateUnwindFees(
      _maxStrikeCollateral.optionsAmount
    );

    for (uint256 i = 0; i < _maxStrikeCollateral.maxStrikes.length; ) {
      // Unwind from maxStrike
      _unwind(
        epoch,
        _maxStrikeCollateral.maxStrikes[i],
        ((_maxStrikeCollateral.optionsAmount + unwindFees) *
          _maxStrikeCollateral.weights[i]) / 1e18
      );
      unchecked {
        ++i;
      }
    }

    unwindAmount = _maxStrikeCollateral.optionsAmount + unwindFees;

    delete maxStrikesCollaterals[epoch][
      userMaxStrikesCollaterals[epoch][msg.sender][maxStrikesCollateralIndex]
    ];

    _validate(_transferIn(addresses.baseToken) == unwindAmount, 33);

    emit Unwind(
      epoch,
      _maxStrikeCollateral.optionStrike,
      unwindAmount,
      msg.sender
    );
  }

  /// @dev Helper function to update states within max strikes
  function _unwind(
    uint256 epoch,
    uint256 maxStrike,
    uint256 underlyingAmount
  ) private {
    checkpoints[epoch][maxStrike][maxStrikeCheckpointsCount[epoch][maxStrike]]
      .underlyingCollected += underlyingAmount;

    emit Unwind(epoch, maxStrike, underlyingAmount, msg.sender);
  }

  /** @notice Unlock collateral to borrow against AP option. Only Callable by managed contracts
   * @param maxStrikesCollateralIndex Index in MaxStrikesCollaterals[] array
   * @param to Collateral to transfer to
   */
  function unlockCollateral(uint256 maxStrikesCollateralIndex, address to)
    external
    whenNotPaused
    isEligibleSender
    returns (uint256 totalCollateral)
  {
    _isManagedContract();

    uint256 epoch = currentEpoch;

    _validate(_isVaultReady(epoch), 17);

    _validate(userMaxStrikesCollaterals[epoch][msg.sender].length > 0, 31);

    MaxStrikesCollateral memory _maxStrikeCollateral = maxStrikesCollaterals[
      epoch
    ][userMaxStrikesCollaterals[epoch][msg.sender][maxStrikesCollateralIndex]];

    _validate(to != address(0), 1);
    _validate(_maxStrikeCollateral.user != address(0), 28);
    _validate(_maxStrikeCollateral.collateralUnlock.expiryDelta == 0, 29);

    uint256 fundingRate = calculateFunding(
      _maxStrikeCollateral.collateralUnlock.collateralAccess,
      epoch
    );

    uint256 expiryDelta = _getTimeLeftTillExpiry(epoch);

    // Unlock collateral from max strikes
    for (uint256 i = 0; i < _maxStrikeCollateral.maxStrikes.length; ) {
      _unlockCollateral(
        epoch,
        _maxStrikeCollateral.maxStrikes[i],
        // Required collateral
        (_maxStrikeCollateral.collateralUnlock.collateralAccess *
          _maxStrikeCollateral.weights[i]) / 1e18,
        (((fundingRate * expiryDelta) / 1e18) *
          _maxStrikeCollateral.weights[i]) / 1e18
      );
      unchecked {
        ++i;
      }
    }

    totalCollateral =
      _maxStrikeCollateral.collateralUnlock.collateralAccess -
      ((fundingRate * expiryDelta) / 1e18);

    epochVaultStates[epoch].totalEpochUnlockedCollateral += _maxStrikeCollateral
      .collateralUnlock
      .collateralAccess;

    _maxStrikeCollateral.collateralUnlock.fundingRate = fundingRate;

    _maxStrikeCollateral.collateralUnlock.expiryDelta = expiryDelta;

    maxStrikesCollaterals[epoch][
      userMaxStrikesCollaterals[epoch][msg.sender][maxStrikesCollateralIndex]
    ] = _maxStrikeCollateral;

    _transferOut(addresses.quoteToken, to, totalCollateral);

    emit UnlockCollateral(
      epoch,
      _maxStrikeCollateral.optionStrike,
      totalCollateral,
      msg.sender
    );
  }

  /**
   * @notice Re-locks collateral into an atlatic option. Withdraws underlying back to user, sends collateral back
   * from dopex managed contract to option, deducts remainder of funding fees.
   * Handles exceptions where collateral may get stuck due to failures in other protocols.
   * @param maxStrikesCollateralIndex Index in userMaxStrikeCollaterals[]
   */
  function relockCollateral(uint256 maxStrikesCollateralIndex)
    external
    whenNotPaused
    isEligibleSender
    returns (uint256 collateralToCollect)
  {
    uint256 epoch = currentEpoch;

    _validate(_isVaultReady(epoch), 17);

    _isManagedContract();
    _validate(userMaxStrikesCollaterals[epoch][msg.sender].length > 0, 31);

    (
      uint256 fundingCharged,
      uint256 prevFundingCharged,
      MaxStrikesCollateral memory _maxStrikeCollateral
    ) = onRelockCollateral(maxStrikesCollateralIndex, epoch, msg.sender);

    _validate(_maxStrikeCollateral.collateralUnlock.expiryDelta != 0, 29);

    uint256 fundingToDeduct = prevFundingCharged - fundingCharged;

    for (uint256 i = 0; i < _maxStrikeCollateral.maxStrikes.length; ) {
      _relockCollateral(
        epoch,
        _maxStrikeCollateral.maxStrikes[i],
        ((_maxStrikeCollateral.collateralUnlock.collateralAccess *
          _maxStrikeCollateral.weights[i]) / 1e18),
        (fundingToDeduct * _maxStrikeCollateral.weights[i]) / 1e18
      );

      unchecked {
        ++i;
      }
    }

    // Delete funding rate
    maxStrikesCollaterals[epoch][
      userMaxStrikesCollaterals[epoch][msg.sender][maxStrikesCollateralIndex]
    ].collateralUnlock.expiryDelta = 0;

    epochVaultStates[epoch].totalEpochUnlockedCollateral -= _maxStrikeCollateral
      .collateralUnlock
      .collateralAccess;

    collateralToCollect =
      _maxStrikeCollateral.collateralUnlock.collateralAccess -
      fundingToDeduct;

    _validate(_transferIn(addresses.quoteToken) >= collateralToCollect, 33);
  }

  /// @notice Calulcates funding based time left for expiry using funding rate
  /// @param maxStrikesCollateralIndex Funding rate when collateral was unlocked
  function onRelockCollateral(
    uint256 maxStrikesCollateralIndex,
    uint256 epoch,
    address user
  )
    public
    view
    returns (
      uint256 fundingCharged,
      uint256 prevFundingCharged,
      MaxStrikesCollateral memory _maxStrikeCollateral
    )
  {
    _maxStrikeCollateral = maxStrikesCollaterals[epoch][
      userMaxStrikesCollaterals[epoch][user][maxStrikesCollateralIndex]
    ];
    uint256 currentFunding = (_maxStrikeCollateral
      .collateralUnlock
      .fundingRate * _getTimeLeftTillExpiry(epoch)) / 1e18;
    prevFundingCharged = ((_maxStrikeCollateral.collateralUnlock.fundingRate *
      _maxStrikeCollateral.collateralUnlock.expiryDelta) / 1e18);

    _validate(prevFundingCharged > 0, 31);
    fundingCharged = prevFundingCharged - currentFunding;
  }

  function _relockCollateral(
    uint256 epoch,
    uint256 maxStrike,
    uint256 collateralAmount,
    uint256 refund
  ) private {
    uint256 checkpoint = maxStrikeCheckpointsCount[epoch][maxStrike];
    // Add back to max strike liquidity balance
    checkpoints[epoch][maxStrike][checkpoint]
      .liquidityBalance += collateralAmount;

    checkpoints[epoch][maxStrike][checkpoint].refund += refund;

    checkpoints[epoch][maxStrike][checkpoint]
      .unlockedCollateral -= collateralAmount;

    emit RelockCollateral(epoch, maxStrike, collateralAmount, msg.sender);
  }

  /**
   * @notice Withdraws balances for a strike from epoch deposted in to current epoch
   * @param maxStrike maxstrike to withdraw from
   */
  function withdraw(uint256 maxStrike, uint256 epoch)
    external
    whenNotPaused
    nonReentrant
    isEligibleSender
    returns (
      uint256 userWithdrawableAmount,
      uint256 premium,
      uint256 funding,
      uint256 underlying
    )
  {
    _validate(epochVaultStates[epoch].isVaultExpired, 17);
    _validate(userEpochDeposits[maxStrike][msg.sender].length > 0, 25);

    uint256 totalUserDeposits;

    uint256 checkpoint = maxStrikeCheckpointsCount[epoch][maxStrike];

    (totalUserDeposits, premium, funding, underlying) = _withdraw(
      maxStrike,
      epoch
    );

    userWithdrawableAmount =
      (totalUserDeposits *
        (checkpoints[epoch][maxStrike][checkpoint].liquidityBalance -
          checkpoints[epoch][maxStrike][checkpoint].refund)) /
      checkpoints[epoch][maxStrike][checkpoint].liquidity;

    _transferOut(
      addresses.quoteToken,
      msg.sender,
      premium + userWithdrawableAmount + funding
    );
    _transferOut(addresses.baseToken, msg.sender, underlying);

    delete userEpochDeposits[maxStrike][msg.sender];

    emit NewWithdraw(
      epoch,
      maxStrike,
      msg.sender,
      userWithdrawableAmount,
      premium,
      funding,
      underlying
    );

    return (userWithdrawableAmount, premium, funding, underlying);
  }

  /**
   * @notice Bootstraps a new epoch and mints option tokens equivalent to user deposits for the epoch
   */
  function bootstrap(uint256 expiry) external nonReentrant onlyOwner {
    uint256 nextEpoch = currentEpoch + 1;

    VaultState memory _vaultState = epochVaultStates[nextEpoch];

    if (currentEpoch > 0)
      _validate(epochVaultStates[nextEpoch - 1].isVaultExpired, 20);

    // Set the next epoch start time
    _vaultState.startTime = block.timestamp;

    _vaultState.expiryTime = expiry;

    _vaultState.isVaultReady = true;

    // Increase the current epoch
    currentEpoch = nextEpoch;

    epochVaultStates[nextEpoch] = _vaultState;

    emit Bootstrap(nextEpoch);
  }

  /*==== VIEWS ====*/

  function getTickSize() external view returns (uint256) {
    return vaultConfiguration.tickSize;
  }

  /**
   * @notice Calculate unwind fees based on underlying amount
   * @param underlyingAmount amount underlying/base token amount
   * @return fee Unwind fees
   */
  function calculateUnwindFees(uint256 underlyingAmount)
    public
    view
    returns (uint256)
  {
    return (underlyingAmount * vaultConfiguration.unwindFee) / 1e18;
  }

  /// @notice Calculate Fees for settlement of options
  /// @param settlementPrice settlement price of BaseToken
  /// @param pnl total pnl
  /// @param amount amount of options being settled
  function calculateSettlementFees(
    uint256 settlementPrice,
    uint256 pnl,
    uint256 amount
  ) public view returns (uint256) {
    return
      IFeeStrategy(addresses.feeStrategy).calculateSettlementFees(
        settlementPrice,
        pnl,
        amount
      ) / 1e12;
  }

  /// @notice Calculate Fees for purchase
  /// @param strike strike price of the BaseToken option
  /// @param amount amount of options being bought
  /// @return the purchase fee in QuoteToken
  function calculatePurchaseFees(uint256 strike, uint256 amount)
    public
    view
    returns (uint256)
  {
    return (IFeeStrategy(addresses.feeStrategy).calculatePurchaseFees(
      getUsdPrice(),
      strike,
      amount
    ) / 1e10);
  }

  /// @notice Calculate premium for an option
  /// @param _strike Strike price of the option
  /// @param _amount Amount of options
  /// @return premium in QuoteToken
  function calculatePremium(uint256 _strike, uint256 _amount)
    public
    view
    returns (uint256 premium)
  {
    uint256 currentPrice = getUsdPrice();
    premium =
      (IOptionPricing(addresses.optionPricing).getOptionPrice(
        true, // isPut
        epochVaultStates[currentEpoch].expiryTime,
        _strike,
        currentPrice,
        getVolatility(_strike)
      ) * _amount) /
      1e20;
  }

  /// @notice Calculate Pnl
  /// @param price price of BaseToken
  /// @param strike strike price of the option
  /// @param amount amount of options
  function calculatePnl(
    uint256 price,
    uint256 strike,
    uint256 amount
  ) public pure returns (uint256) {
    return strike > price ? ((strike - price) * amount) / 1e20 : 0;
  }

  /**
   * @notice Returns the price of the BaseToken in USD
   */
  function getUsdPrice() public view returns (uint256) {
    return uint256(IPriceOracle(addresses.priceOracle).latestAnswer());
  }

  /// @notice Returns the volatility from the volatility oracle
  /// @param _strike Strike of the option
  function getVolatility(uint256 _strike) public view returns (uint256) {
    return IVolatilityOracle(addresses.volatilityOracle).getVolatility(_strike);
  }

  /// @notice Returns cumulative liquidity for a given strike
  /// @return cumulativeLiquidity cumulativeLiquidity up to given strike
  function getCumulativeLiquidity(uint256 epoch)
    public
    view
    returns (uint256 cumulativeLiquidity)
  {
    uint256 nextNode = epochVaultStates[epoch].maxStrikeRange[0];
    uint256 checkpoint;
    while (nextNode != 0) {
      checkpoint = maxStrikeCheckpointsCount[epoch][nextNode];
      cumulativeLiquidity +=
        checkpoints[epoch][nextNode][checkpoint].liquidity -
        checkpoints[epoch][nextNode][checkpoint].activeCollateral;
      (, nextNode) = epochStrikesList[epoch].getNextNode(nextNode);
    }
  }

  /// @notice Returns liquidity for a given max strike
  /// @param maxStrike max strike to get liquidity for
  function getLiquidityForStrike(uint256 maxStrike, uint256 epoch)
    public
    view
    returns (uint256)
  {
    uint256 checkpoint = maxStrikeCheckpointsCount[epoch][maxStrike];
    return
      checkpoints[epoch][maxStrike][checkpoint].liquidity -
      checkpoints[epoch][maxStrike][checkpoint].activeCollateral;
  }

  /// @notice Returns max strike from maxStrikes mapping. Also Getter/helper for getSortedSpot
  /// @param _strike key/node to retrieve
  function _getValue(uint256 _strike, uint256 epoch)
    private
    view
    returns (uint256)
  {
    if (isValidStrike[epoch][_strike]) {
      return _strike;
    } else {
      return 0;
    }
  }

  /// @dev Gets tail of the linked list
  function _getSortedSpot(uint256 _value) private view returns (uint256) {
    uint256 epoch = currentEpoch;
    if (epochStrikesList[epoch].sizeOf() == 0) {
      return 0;
    }

    uint256 next;
    (, next) = epochStrikesList[epoch].getAdjacent(0, true);
    // Switch to descending
    while ((next != 0) && ((_value < _getValue(next, currentEpoch)) == true)) {
      next = epochStrikesList[epoch].list[next][true];
    }
    return next;
  }

  /**
   * @param strike Strike of the option
   * @param epoch Epoch of atlantic pool to inquire
   * @return uint256Cache Total deposits of user
   * @return premium Total premiums earned
   * @return funding Total funding fees earned
   */
  function _withdraw(uint256 strike, uint256 epoch)
    private
    returns (
      // Variable is reused to avoid stack to deep
      uint256 uint256Cache,
      uint256 premium,
      uint256 funding,
      uint256 underlying
    )
  {
    // Instance of indexes of user's deposits
    uint256[] memory indexes = userEpochDeposits[strike][msg.sender];
    // Instance of Deposit struct Array containing all deposits
    Deposit[] memory deposits = epochDeposits[epoch];

    // User deposit amount
    uint256 userDepositAmount;

    uint256Cache = maxStrikeCheckpointsCount[epoch][strike];

    // Last updated premium distribution ratio
    uint256 premiumRatio = checkpoints[epoch][strike][uint256Cache]
      .premiumDistributionRatio;

    // Last updated funding distribution ratio
    uint256 fundingRatio = checkpoints[epoch][strike][uint256Cache]
      .fundingDistributionRatio;

    // Last updated funding distribution ratio
    uint256 underlyingRatio = checkpoints[epoch][strike][uint256Cache]
      .underlyingDistributionRatio;

    // [0] -> userPremiumRatio
    // [1] -> userFundingRatio
    // [2] -> userUnderlyingRatio
    uint256[3] memory ratios; //userPremiumRatio

    uint256Cache = 0;

    for (uint256 i = 0; i < indexes.length; ) {
      userDepositAmount = deposits[indexes[i]].liquidity;
      ratios[0] = deposits[indexes[i]].premiumDistributionRatio;
      ratios[1] = deposits[indexes[i]].fundingDistributionRatio;
      ratios[2] = deposits[indexes[i]].underlyingDistributionRatio;

      premium += ((premiumRatio - ratios[0]) * userDepositAmount) / 1e18;

      funding += ((fundingRatio - ratios[1]) * userDepositAmount) / 1e18;

      underlying += ((underlyingRatio - ratios[2]) * userDepositAmount) / 1e18;

      uint256Cache += userDepositAmount;

      delete epochDeposits[epoch][indexes[i]];

      unchecked {
        ++i;
      }
    }
    delete userEpochDeposits[strike][msg.sender];
  }

  /// @notice Returns user's deposit keys
  /// @param maxStrike Max strike
  /// @param user User to look up
  /// @return result liquidity amounts user has deposited
  function getEpochUserDepositKeys(uint256 maxStrike, address user)
    external
    view
    returns (uint256[] memory result)
  {
    result = new uint256[](userEpochDeposits[maxStrike][user].length);
    result = userEpochDeposits[maxStrike][user];
  }

  function getEpochData(uint256 epoch, uint256 maxStrike)
    external
    view
    returns (Checkpoint memory checkpoint)
  {
    return
      checkpoints[epoch][maxStrike][
        maxStrikeCheckpointsCount[epoch][maxStrike]
      ];
  }

  /// @notice Return all deposit instances
  /// @param epoch Max strike
  function getEpochDeposits(uint256 epoch)
    external
    view
    returns (Deposit[] memory result)
  {
    result = new Deposit[](epochDeposits[epoch].length);
    result = epochDeposits[epoch];
  }

  /// @notice Collateral utilization rate
  /// @param epoch Epoch of the pool
  /// @return utilizationRate in 1e8 decimals
  function getUtilizationRate(uint256 epoch) public view returns (uint256) {
    uint256 activeCollateral = epochVaultStates[epoch]
      .totalEpochActiveCollateral;
    uint256 unlockedCollateral = epochVaultStates[epoch]
      .totalEpochUnlockedCollateral;

    if (activeCollateral == 0 || unlockedCollateral == 0) {
      return 0;
    } else {
      return ((unlockedCollateral * 1e6) / activeCollateral);
    }
  }

  /// @notice Fetches all max strikes written in a epoch
  /// @param epoch Epoch of the pool
  /// @return maxStrikes
  function getEpochMaxStrikes(uint256 epoch)
    external
    view
    returns (uint256[] memory maxStrikes)
  {
    maxStrikes = new uint256[](epochStrikesList[epoch].sizeOf());

    uint256 nextNode = epochVaultStates[epoch].maxStrikeRange[0];
    uint256 iterator;
    while (nextNode != 0) {
      maxStrikes[iterator] = nextNode;
      iterator++;
      (, nextNode) = epochStrikesList[epoch].getNextNode(nextNode);
    }
  }

  /// @notice Fetches latest checkpoints of all maxstrikes
  /// @param epoch Epoch of the pool
  /// @return _checkpoints
  function getEpochCurrentMaxStrikeCheckpoints(uint256 epoch)
    external
    view
    returns (uint256[] memory _checkpoints)
  {
    _checkpoints = new uint256[](epochStrikesList[epoch].sizeOf());
    uint256 nextNode = epochVaultStates[epoch].maxStrikeRange[0];
    uint256 iterator;
    while (nextNode != 0) {
      _checkpoints[iterator] = maxStrikeCheckpointsCount[epoch][nextNode];
      iterator++;
      (, nextNode) = epochStrikesList[epoch].getNextNode(nextNode);
    }
  }

  /// @notice Get funding rate for borrowing deposits against AP options
  /// @param epoch Epoch of the pool
  /// @return fundingRate Funding rate in 1e6 decimals
  function getFundingRate(uint256 epoch)
    public
    view
    returns (uint256 fundingRate)
  {
    fundingRate =
      vaultConfiguration.baseFundingRate +
      ((vaultConfiguration.collateralUtilizationWeight *
        getUtilizationRate(epoch)) / 1e6);
  }

  /// @notice Calculate funding fees to pay using underlying token
  /// @param totalCollateral Total collateral in quote token in 1e6 decimals
  function calculateFunding(uint256 totalCollateral, uint256 epoch)
    public
    view
    returns (uint256 funding)
  {
    funding = (totalCollateral * getFundingRate(epoch)) / 1e6;
  }

  /// @return result Days remaining in 1e18 decimals
  function _getTimeLeftTillExpiry(uint256 epoch)
    private
    view
    returns (uint256 result)
  {
    result =
      ((((epochVaultStates[epoch].expiryTime - block.timestamp) * 1e36) /
        86400e18) * 1e18) /
      365e18;
  }

  /// @notice Returns nax strike collaterals of an options purchase
  /// @return result Max strike collaterals of an options purchase
  function getUserMaxStrikesCollaterals(address user, uint256 epoch)
    external
    view
    returns (MaxStrikesCollateral[] memory result)
  {
    result = new MaxStrikesCollateral[](
      userMaxStrikesCollaterals[epoch][user].length
    );

    for (uint256 i; i < userMaxStrikesCollaterals[epoch][user].length; ) {
      result[i] = maxStrikesCollaterals[epoch][
        userMaxStrikesCollaterals[epoch][user][i]
      ];
      unchecked {
        ++i;
      }
    }
  }

  /// @dev Fetches all instances of maxStrikesCollateral
  function getEpochMaxStrikesCollaterals(uint256 epoch)
    external
    view
    returns (MaxStrikesCollateral[] memory result)
  {
    result = new MaxStrikesCollateral[](maxStrikesCollaterals[epoch].length);
    result = maxStrikesCollaterals[epoch];
  }

  /**
   *   @notice Checks if caller is managed contract
   */
  function _isManagedContract() private view {
    _validate(managedContracts[msg.sender], 23);
  }

  /// @dev Validator function that calls revert based on the condition given
  function _validate(bool trueCondition, uint256 errorCode) private pure {
    if (!trueCondition) revert AtlanticPutsPoolError(errorCode);
  }

  /// @notice Add max strike to strikesList (linked list)
  /// @param _strike Strike to add to strikesList
  function _addMaxStrike(uint256 _strike, uint256 epoch) private {
    if (_strike > epochVaultStates[epoch].maxStrikeRange[0]) {
      epochVaultStates[epoch].maxStrikeRange[0] = _strike;
    }
    if (
      _strike < epochVaultStates[epoch].maxStrikeRange[1] ||
      epochVaultStates[epoch].maxStrikeRange[1] == 0
    ) {
      epochVaultStates[epoch].maxStrikeRange[1] = _strike;
    }
    // Add new max strike after the next largest strike
    uint256 strikeToInsertAfter = _getSortedSpot(_strike);

    if (strikeToInsertAfter == 0) epochStrikesList[epoch].pushBack(_strike);
    else epochStrikesList[epoch].insertBefore(strikeToInsertAfter, _strike);

    isValidStrike[epoch][_strike] = true;
  }

  /// @notice Adds to max strikes collateral mapping
  /// @param index Index of the array, at which to save to
  /// @param maxStrike Value of the maxStrike to account for
  /// @param weight Amount of collateral used from the max strike
  function _addToMaxStrikesCollateralWeight(
    uint256 index,
    uint256 maxStrike,
    uint256 weight
  ) private {
    uint256 epoch = currentEpoch;

    maxStrikesCollaterals[epoch][index].maxStrikes.push(maxStrike);
    maxStrikesCollaterals[epoch][index].weights.push(weight);
  }

  /// @dev Creates an instance of maxStrikesCollateral
  function _createUserMaxStrikesCollateral(
    uint256 epoch,
    uint256 optionStrike,
    uint256 optionsAmount,
    address user
  ) private {
    uint256[] memory emptyArray;
    maxStrikesCollaterals[epoch].push(
      MaxStrikesCollateral(
        user,
        optionStrike,
        optionsAmount,
        emptyArray,
        emptyArray,
        CollateralUnlock(0, 0, (optionStrike * optionsAmount) / 1e20)
      )
    );
  }

  /**
   * @notice Accounts premiums collected and options written according to liquidity
   * provided by each strike
   * @param strike Strike of the option
   * @param epoch Current epoch
   * @param premium Premium charged to user
   * @param collateralRequired Collateral required/pulled from strikes
   */
  function _purchase(
    uint256 strike,
    uint256 epoch,
    uint256 premium,
    uint256 collateralRequired,
    address user
  ) private returns (uint256 index, uint256 options) {
    uint256 liquidityFromMaxStrikes;
    uint256 liquidityRequired;
    uint256 liquidityProvided;
    uint256 nextNode = epochVaultStates[epoch].maxStrikeRange[0];
    uint256 liquidityAtCurrentStrike;
    uint256 checkpoint;
    index = maxStrikesCollaterals[epoch].length;
    userMaxStrikesCollaterals[epoch][user].push(index);
    _createUserMaxStrikesCollateral(
      epoch,
      strike,
      (collateralRequired * 1e20) / strike,
      user
    );

    // Traverse over nodes until it hits `endNode`
    while (liquidityFromMaxStrikes != collateralRequired) {
      liquidityRequired = collateralRequired - liquidityFromMaxStrikes;
      // Liquidity at current max strike
      liquidityAtCurrentStrike = getLiquidityForStrike(nextNode, epoch);
      checkpoint = maxStrikeCheckpointsCount[epoch][nextNode];

      if (liquidityAtCurrentStrike > 0) {
        // Node has all the required liquidity to fill the purchase
        if (liquidityAtCurrentStrike >= liquidityRequired) {
          // Deduct liquidity from this maxStrike
          liquidityProvided = liquidityRequired;
          // uint256 excess =
          checkpoints[epoch][nextNode][checkpoint]
            .activeCollateral += liquidityRequired;

          _addToMaxStrikesCollateralWeight(
            index,
            nextNode,
            (liquidityProvided * 1e18) / collateralRequired
          );
        } else {
          // Node has lesser liquidity than the remainder of the purchase
          liquidityProvided = liquidityAtCurrentStrike;

          checkpoints[epoch][nextNode][checkpoint]
            .activeCollateral += liquidityProvided;

          _addToMaxStrikesCollateralWeight(
            index,
            nextNode,
            (liquidityProvided * 1e18) / collateralRequired
          );
        }

        // Options written
        options += (liquidityProvided * 1e20) / strike;

        checkpoints[epoch][nextNode][checkpoint].premiumCollected +=
          (liquidityProvided * premium) /
          collateralRequired;

        liquidityFromMaxStrikes += liquidityProvided;
      } // Go to next node
      (, nextNode) = epochStrikesList[epoch].getNextNode(nextNode);
    }
  }

  /// @dev Updates the final epoch eth balances per strike of the vault
  function _expireEpoch() private {
    uint256 epoch = currentEpoch;
    uint256 currentStrike = epochVaultStates[epoch].maxStrikeRange[0];

    while (currentStrike != 0) {
      // Update premium distribution ratio
      (
        uint256 premiumRatio,
        uint256 fundingRatio,
        uint256 underlyingRatio
      ) = onUpdateCheckpoint(epoch, currentStrike);

      _updateCheckpoint(
        epoch,
        currentStrike,
        0,
        0,
        premiumRatio,
        fundingRatio,
        underlyingRatio
      );

      (, currentStrike) = epochStrikesList[epoch].getNextNode(currentStrike);
    }
  }

  /// @dev Returns new premium, funding and underlying ratios. called before updating a checkpoint
  function onUpdateCheckpoint(uint256 epoch, uint256 maxStrike)
    public
    view
    returns (
      uint256 newPremiumRatio,
      uint256 newFundingRatio,
      uint256 newUnderlyingRatio
    )
  {
    uint256 checkpoint = maxStrikeCheckpointsCount[epoch][maxStrike];
    uint256 _deposits = checkpoints[epoch][maxStrike][checkpoint].liquidity;

    if (_deposits > 0) {
      newPremiumRatio =
        ((_getNewPremiumCollected(epoch, maxStrike, checkpoint) * 1e18) /
          _deposits) +
        checkpoints[epoch][maxStrike][checkpoint].premiumDistributionRatio;

      newFundingRatio =
        ((_getNewFundingCollected(epoch, maxStrike, checkpoint) * 1e18) /
          _deposits) +
        checkpoints[epoch][maxStrike][checkpoint].fundingDistributionRatio;

      newUnderlyingRatio =
        ((_getNewUnderlyingCollected(epoch, maxStrike, checkpoint) * 1e18) /
          _deposits) +
        checkpoints[epoch][maxStrike][checkpoint].underlyingDistributionRatio;
    }
  }

  /// @dev Returns new underlying collected between current and last checkpoint
  function _getNewUnderlyingCollected(
    uint256 epoch,
    uint256 maxStrike,
    uint256 checkpoint
  ) private view returns (uint256 result) {
    if (checkpoint > 0) {
      uint256 oldUnderlying = checkpoints[epoch][maxStrike][checkpoint - 1]
        .underlyingCollected;
      uint256 newUnderlying = checkpoints[epoch][maxStrike][checkpoint]
        .underlyingCollected;

      result = oldUnderlying < newUnderlying
        ? newUnderlying - oldUnderlying
        : oldUnderlying - newUnderlying;
    }
  }

  function _isVaultReady(uint256 epoch) private view returns (bool) {
    return
      !epochVaultStates[epoch].isVaultExpired &&
      epochVaultStates[epoch].isVaultReady;
  }

  /// @notice Helper function for unlockCollateral()
  /// @param epoch epoch of the vault
  /// @param maxStrike Max strike to unlock collateral from
  /// @param collateralAmount Amount of collateral to unlock
  function _unlockCollateral(
    uint256 epoch,
    uint256 maxStrike,
    uint256 collateralAmount,
    uint256 funding
  ) private {
    uint256 checkpoint = maxStrikeCheckpointsCount[epoch][maxStrike];

    checkpoints[epoch][maxStrike][checkpoint]
      .unlockedCollateral += collateralAmount;

    checkpoints[epoch][maxStrike][checkpoint]
      .liquidityBalance -= collateralAmount;

    checkpoints[epoch][maxStrike][checkpoint].fundingCollected += funding;

    emit UnlockCollateral(epoch, maxStrike, collateralAmount, msg.sender);
  }

  /// @notice Get the difference in premiums collected between latest and previous checkpoint
  function _getNewPremiumCollected(
    uint256 epoch,
    uint256 maxStrike,
    uint256 checkpoint
  ) private view returns (uint256 result) {
    if (checkpoint > 0) {
      uint256 oldPremium = checkpoints[epoch][maxStrike][checkpoint - 1]
        .premiumCollected;
      uint256 newPremium = checkpoints[epoch][maxStrike][checkpoint]
        .premiumCollected;
      result = oldPremium < newPremium
        ? newPremium - oldPremium
        : oldPremium - newPremium;
    }
  }

  /// @notice Get the difference in funding collected between latest and previous checkpoint
  function _getNewFundingCollected(
    uint256 epoch,
    uint256 maxStrike,
    uint256 checkpoint
  ) private view returns (uint256 result) {
    if (checkpoint > 0) {
      uint256 oldFunding = checkpoints[epoch][maxStrike][checkpoint - 1]
        .fundingCollected;
      uint256 newFunding = checkpoints[epoch][maxStrike][checkpoint]
        .fundingCollected;

      result = oldFunding < newFunding
        ? newFunding - oldFunding
        : oldFunding - newFunding;
    }
  }

  /// @notice Adds a new checkpoint
  function _updateCheckpoint(
    uint256 epoch,
    uint256 maxStrike,
    uint256 liquidity,
    uint256 liquidityBalance,
    uint256 premiumDistributionRatio,
    uint256 fundingDistributionRatio,
    uint256 underlyingDistributionRatio
  ) private {
    uint256 latestCheckpoint = maxStrikeCheckpointsCount[epoch][maxStrike];
    Checkpoint memory prevCheckpoint = checkpoints[epoch][maxStrike][
      latestCheckpoint
    ];

    Checkpoint memory newCheckpoint = Checkpoint(
      prevCheckpoint.premiumCollected,
      prevCheckpoint.fundingCollected,
      prevCheckpoint.underlyingCollected,
      prevCheckpoint.liquidity + liquidity,
      prevCheckpoint.liquidityBalance + liquidityBalance,
      prevCheckpoint.activeCollateral,
      prevCheckpoint.unlockedCollateral,
      prevCheckpoint.refund,
      premiumDistributionRatio,
      fundingDistributionRatio,
      underlyingDistributionRatio
    );

    latestCheckpoint++;
    checkpoints[epoch][maxStrike][latestCheckpoint] = newCheckpoint;
    maxStrikeCheckpointsCount[epoch][maxStrike] = latestCheckpoint;
  }

  function _transferIn(address token) private returns (uint256 result) {
    uint256 newBalance = IERC20(token).balanceOf(address(this));
    uint256 oldBalance = tokenBalances[token];
    result = newBalance - oldBalance;
    tokenBalances[token] = newBalance;
  }

  function _transferOut(
    address token,
    address to,
    uint256 amount
  ) private {
    IERC20(token).safeTransfer(to, amount);
    _updateTokenBalance(token);
  }

  function _updateTokenBalance(address token) private {
    tokenBalances[token] = IERC20(token).balanceOf(address(this));
  }

  /// @dev Fetch premium distribution ratio in latest checkpoint
  function _getPremiumDistributionRatio(
    uint256 epoch,
    uint256 maxStrike,
    uint256 checkpoint
  ) private view returns (uint256) {
    return checkpoints[epoch][maxStrike][checkpoint].premiumDistributionRatio;
  }

  // /*==== MODIFIERS ====*/

  modifier onlyGovernance() {
    _validate(msg.sender == addresses.governance, 21);
    _;
  }
}

// ERROR MAPPING:
// {
//   "E1": "AtlanticPool: Address cannot be a zero address",
//   "E2": "AtlanticPool: Input array lengths must match",
//   "E3": "AtlanticPool: Epoch has expired",
//   "E4": "AtlanticPool: Cannot expire epoch before epoch's expiry",
//   "E5": "AtlanticPool: Expire delay tolerance exceeded",
//   "E6": "AtlanticPool: Max strike must be divisble by tick size",
//   "E7": "AtlanticPool: Max strike must be greater than zero",
//   "E8": "AtlanticPool: Max strike must be lower than current price",
//   "E9": "AtlanticPool: Zero input for liquidity",
//   "E10": "AtlanticPool: Vault not bootstrapped",
//   "E11": "AtlanticPool: Invalid strike",
//   "E12": "AtlanticPool: Invalid amount",
//   "E13": "AtlanticPool: Insufficient liquidity",
//   "E14": "AtlanticPool: Epoch already bootstrapped",
//   "E15": "AtlanticPool: Option is out the money",
//   "E16": "AtlanticPool: Option token balance is not enough",
//   "E17": "AtlanticPool: Epoch must be expired",
//   "E20": "AtlanticPool: Previous epoch not expired",
//   "E21": "AtlanticPool: Caller is not governance",
//   "E22": "AtlanticPool: Expire delay tolerance exceeded",
//   "E23": "AtlanticPool: Only managed contract can call this function",
//   "E24": "AtlanticPool: Grace period of settlement bypassed",
//   "E25": "AtlanticPool: No deposits",
//   "E26": "AtlanticPool: Invalid funding token",
//   "E27": "AtlanticPool: Forbidden",
//   "E28": "AtlanticPool: Invalid max strikes collateral index",
//   "E29": "AtlanticPool: Already unlocked, Relock first",
//   "E30": "AtlanticPool: Vault has not been configured",
//   "E31": "AtlanticPool: No maxStrikeCollaters found",
//   "E32": "AtlanticPool: Not in exercise window",
//   "E33": "AtlanticPool: Invalid trasnfer in",
// }