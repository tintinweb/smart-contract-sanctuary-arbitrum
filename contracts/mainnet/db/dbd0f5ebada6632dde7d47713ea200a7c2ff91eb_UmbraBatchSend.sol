// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IUmbra} from "src/interface/IUmbra.sol";

/// @notice This contract allows for batch sending ETH and tokens via Umbra.
contract UmbraBatchSend is Ownable {
  using SafeERC20 for IERC20;

  /// @dev Special address used to indicate the chain's native asset, e.g. ETH.
  address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @notice Address of the Umbra contract.
  IUmbra public immutable UMBRA;

  /// @dev Data for a single payment.
  struct SendData {
    address receiver; // Stealth address.
    address tokenAddr; // Token being sent, or the above `ETH` address for the chain's native asset.
    uint256 amount; // Amount of the token to send, excluding the toll.
    bytes32 pkx; // Ephemeral public key x coordinate.
    bytes32 ciphertext; // Encrypted entropy.
  }

  /// @dev Emitted on a successful batch send.
  event BatchSendExecuted(address indexed sender);

  /// @dev Thrown when the array of SendData structs is not sorted by token address.
  error NotSorted();

  /// @dev Thrown when too much ETH was sent to the contract.
  error TooMuchEthSent();

  /// @param _umbra Address of the Umbra contract.
  constructor(IUmbra _umbra) {
    UMBRA = _umbra;
  }

  /// @notice Batch send ETH and tokens via Umbra.
  /// @param _tollCommitment The toll commitment to use for all payments.
  /// @param _data Array of SendData structs, each containing the data for a single payment.
  /// Must be sorted by token address, with `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` used as
  /// the token address for the chain's native asset.
  function batchSend(uint256 _tollCommitment, SendData[] calldata _data) external payable {
    uint256 _initEthBalance = address(this).balance; // Includes ETH from msg.value.

    // First we pull the required token amounts into this contract.
    uint256 _len = _data.length;
    uint256 _index;
    address _currentToken;

    while (_index < _len) {
      uint256 _amount;

      if (_data[_index].tokenAddr < _currentToken) revert NotSorted();
      _currentToken = _data[_index].tokenAddr;

      do {
        _amount += _data[_index].amount;
        _index = _uncheckedIncrement(_index);
      } while (_index < _len && _data[_index].tokenAddr == _currentToken);

      _pullToken(_currentToken, _amount);
    }

    // Next we send the payments.
    for (uint256 i = 0; i < _len; i = _uncheckedIncrement(i)) {
      if (_data[i].tokenAddr == ETH) {
        UMBRA.sendEth{value: _data[i].amount + _tollCommitment}(
          payable(_data[i].receiver), _tollCommitment, _data[i].pkx, _data[i].ciphertext
        );
      } else {
        UMBRA.sendToken{value: _tollCommitment}(
          _data[i].receiver, _data[i].tokenAddr, _data[i].amount, _data[i].pkx, _data[i].ciphertext
        );
      }
    }

    // If excess ETH was sent, revert.
    if (address(this).balance != _initEthBalance - msg.value) revert TooMuchEthSent();
    emit BatchSendExecuted(msg.sender);
  }

  /// @dev Pulls the specified amount of the given token into this contract, and is a no-op for
  /// the native token.
  function _pullToken(address _tokenAddr, uint256 _amount) internal {
    if (_tokenAddr != ETH) IERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), _amount);
  }

  /// @notice Whenever a new token is added to Umbra, this method must be called by the owner to
  /// support that token in this contract.
  function approveToken(IERC20 _token) external onlyOwner {
    _token.safeApprove(address(UMBRA), type(uint256).max);
  }

  /// @dev Increments a uint256 without reverting on overflow.
  function _uncheckedIncrement(uint256 i) internal pure returns (uint256) {
    unchecked {
      return i + 1;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IUmbraHookReceiver} from "src/interface/IUmbraHookReceiver.sol";

interface IUmbra {
  /**
   * @notice Public state variable get function
   * @return uint256 toll
   */
  function toll() external returns (uint256);

  /**
   * @notice Admin only function to update the toll
   * @param _newToll New ETH toll in wei
   */
  function setToll(uint256 _newToll) external;

  /**
   * @notice Admin only function to update the toll collector
   * @param _newTollCollector New address which has fund sweeping privileges
   */
  function setTollCollector(address _newTollCollector) external;

  /**
   * @notice Admin only function to update the toll receiver
   * @param _newTollReceiver New address which receives collected funds
   */
  function setTollReceiver(address payable _newTollReceiver) external;

  /**
   * @notice Function only the toll collector can call to sweep funds to the toll receiver
   */
  function collectTolls() external;

  // ======================
  // ======== Send ========
  // ======================

  /**
   * @notice Send and announce ETH payment to a stealth address
   * @param _receiver Stealth address receiving the payment
   * @param _tollCommitment Exact toll the sender is paying; should equal contract toll;
   * the commitment is used to prevent frontrunning attacks by the owner;
   * see https://github.com/ScopeLift/umbra-protocol/issues/54 for more information
   * @param _pkx X-coordinate of the ephemeral public key used to encrypt the payload
   * @param _ciphertext Encrypted entropy (used to generated the stealth address) and payload
   * extension
   */
  function sendEth(
    address payable _receiver,
    uint256 _tollCommitment,
    bytes32 _pkx, // ephemeral public key x coordinate
    bytes32 _ciphertext
  ) external payable;

  /**
   * @notice Send and announce an ERC20 payment to a stealth address
   * @param _receiver Stealth address receiving the payment
   * @param _tokenAddr Address of the ERC20 token being sent
   * @param _amount Amount of the token to send, in its own base units
   * @param _pkx X-coordinate of the ephemeral public key used to encrypt the payload
   * @param _ciphertext Encrypted entropy (used to generated the stealth address) and payload
   * extension
   */
  function sendToken(
    address _receiver,
    address _tokenAddr,
    uint256 _amount,
    bytes32 _pkx, // ephemeral public key x coordinate
    bytes32 _ciphertext
  ) external payable;

  // ==========================
  // ======== Withdraw ========
  // ==========================

  /**
   * @notice Withdraw an ERC20 token payment sent to a stealth address
   * @dev This method must be directly called by the stealth address
   * @param _acceptor Address where withdrawn funds should be sent
   * @param _tokenAddr Address of the ERC20 token being withdrawn
   */
  function withdrawToken(address _acceptor, address _tokenAddr) external;

  /**
   * @notice Withdraw an ERC20 token payment sent to a stealth address
   * @dev This method must be directly called by the stealth address
   * @param _acceptor Address where withdrawn funds should be sent
   * @param _tokenAddr Address of the ERC20 token being withdrawn
   * @param _hook Contract that will be called after the token withdrawal has completed
   * @param _data Arbitrary data that will be passed to the post-withdraw hook contract
   */
  function withdrawTokenAndCall(
    address _acceptor,
    address _tokenAddr,
    IUmbraHookReceiver _hook,
    bytes memory _data
  ) external;

  /**
   * @notice Withdraw an ERC20 token payment on behalf of a stealth address via signed authorization
   * @param _stealthAddr The stealth address whose token balance will be withdrawn
   * @param _acceptor Address where withdrawn funds should be sent
   * @param _tokenAddr Address of the ERC20 token being withdrawn
   * @param _sponsor Address which is compensated for submitting the withdrawal tx
   * @param _sponsorFee Amount of the token to pay to the sponsor
   * @param _v ECDSA signature component: Parity of the `y` coordinate of point `R`
   * @param _r ECDSA signature component: x-coordinate of `R`
   * @param _s ECDSA signature component: `s` value of the signature
   */
  function withdrawTokenOnBehalf(
    address _stealthAddr,
    address _acceptor,
    address _tokenAddr,
    address _sponsor,
    uint256 _sponsorFee,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;

  /**
   * @notice Withdraw an ERC20 token payment on behalf of a stealth address via signed authorization
   * @param _stealthAddr The stealth address whose token balance will be withdrawn
   * @param _acceptor Address where withdrawn funds should be sent
   * @param _tokenAddr Address of the ERC20 token being withdrawn
   * @param _sponsor Address which is compensated for submitting the withdrawal tx
   * @param _sponsorFee Amount of the token to pay to the sponsor
   * @param _hook Contract that will be called after the token withdrawal has completed
   * @param _data Arbitrary data that will be passed to the post-withdraw hook contract
   * @param _v ECDSA signature component: Parity of the `y` coordinate of point `R`
   * @param _r ECDSA signature component: x-coordinate of `R`
   * @param _s ECDSA signature component: `s` value of the signature
   */
  function withdrawTokenAndCallOnBehalf(
    address _stealthAddr,
    address _acceptor,
    address _tokenAddr,
    address _sponsor,
    uint256 _sponsorFee,
    IUmbraHookReceiver _hook,
    bytes memory _data,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @dev Interface that post-withdraw hooks must implement to interop with Umbra
interface IUmbraHookReceiver {
  /**
   * @notice Method called after a user completes an Umbra token withdrawal
   * @param _amount The amount of the token withdrawn _after_ subtracting the sponsor fee
   * @param _stealthAddr The stealth address whose token balance was withdrawn
   * @param _acceptor Address where withdrawn funds were sent; can be this contract
   * @param _tokenAddr Address of the ERC20 token that was withdrawn
   * @param _sponsor Address which was compensated for submitting the withdrawal tx
   * @param _sponsorFee Amount of the token that was paid to the sponsor
   * @param _data Arbitrary data passed to this hook by the withdrawer
   */
  function tokensWithdrawn(
    uint256 _amount,
    address _stealthAddr,
    address _acceptor,
    address _tokenAddr,
    address _sponsor,
    uint256 _sponsorFee,
    bytes memory _data
  ) external;
}