// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

import './RouterStorage.sol';

struct AdapterCallbackData {
  address payer;
  address tokenIn;
  uint256 dexIndex;
}

abstract contract AdapterCallback is RouterStorage {
  /// @inheritdoc IMarginlyRouter
  function adapterCallback(address recipient, uint256 amount, bytes calldata _data) external {
    AdapterCallbackData memory data = abi.decode(_data, (AdapterCallbackData));
    require(msg.sender == adapters[data.dexIndex]);
    TransferHelper.safeTransferFrom(data.tokenIn, data.payer, recipient, amount);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import '@openzeppelin/contracts/access/Ownable2Step.sol';

import '../interfaces/IMarginlyAdapter.sol';
import '../interfaces/IMarginlyRouter.sol';

struct AdapterInput {
  uint256 dexIndex;
  address adapter;
}

abstract contract RouterStorage is IMarginlyRouter, Ownable2Step {
  /// @notice Emitted when new adapter is added
  event NewAdapter(uint256 dexIndex, address indexed adapter);

  error UnknownDex();

  mapping(uint256 => address) public adapters;

  constructor(AdapterInput[] memory _adapters) {
    AdapterInput memory input;
    uint256 length = _adapters.length;
    for (uint256 i; i < length; ) {
      input = _adapters[i];
      adapters[input.dexIndex] = input.adapter;
      emit NewAdapter(input.dexIndex, input.adapter);

      unchecked {
        ++i;
      }
    }
  }

  function addDexAdapters(AdapterInput[] calldata _adapters) external onlyOwner {
    AdapterInput memory input;
    uint256 length = _adapters.length;
    for (uint256 i; i < length; ) {
      input = _adapters[i];
      adapters[input.dexIndex] = input.adapter;
      emit NewAdapter(input.dexIndex, input.adapter);

      unchecked {
        ++i;
      }
    }
  }

  function getAdapterSafe(uint256 dexIndex) internal view returns (IMarginlyAdapter) {
    address adapterAddress = adapters[dexIndex];
    if (adapterAddress == address(0)) revert UnknownDex();
    return IMarginlyAdapter(adapterAddress);
  }

  function renounceOwnership() public override onlyOwner {
    revert Forbidden();
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

interface IMarginlyAdapter {
  error InsufficientAmount();
  error TooMuchRequested();
  error NotSupported();

  /// @notice swap with exact input
  /// @param recipient recipient of amountOut of tokenOut
  /// @param tokenIn address of a token to swap on dex
  /// @param tokenOut address of a token to receive from dex
  /// @param amountIn exact amount of tokenIn to swap
  /// @param minAmountOut minimal amount of tokenOut to receive
  /// @param data data for AdapterCallback
  function swapExactInput(
    address recipient,
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut,
    bytes calldata data
  ) external returns (uint256 amountOut);

  /// @notice swap with exact output
  /// @param recipient recipient of amountOut of tokenOut
  /// @param tokenIn address of a token to swap on dex
  /// @param tokenOut address of a token to receive from dex
  /// @param maxAmountIn maximal amount of tokenIn to swap
  /// @param amountOut exact amount of tokenOut to receive
  /// @param data data for AdapterCallback
  function swapExactOutput(
    address recipient,
    address tokenIn,
    address tokenOut,
    uint256 maxAmountIn,
    uint256 amountOut,
    bytes calldata data
  ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import '../abstract/AdapterCallback.sol';
import '../abstract/RouterStorage.sol';

interface IMarginlyRouter {
  /// @notice Emitted when swap with zero input or output was called
  error ZeroAmount();
  /// @notice Emitted if balance difference doesn't equal amountOut
  error WrongAmountOut();
  /// @notice Emitted when trying to renounce ownership
  error Forbidden();

  /// @notice Emitted when swap happened
  /// @param isExactInput true if swapExactInput, false if swapExactOutput
  /// @param dexIndex index of the dex used for swap
  /// @param receiver swap result receiver
  /// @param tokenIn address of a token swapped on dex
  /// @param tokenOut address of a token received from dex
  /// @param amountIn amount of tokenIn swapped
  /// @param amountOut amount of tokenOut received
  event Swap(
    bool isExactInput,
    uint256 dexIndex,
    address indexed receiver,
    address indexed tokenIn,
    address indexed tokenOut,
    uint256 amountIn,
    uint256 amountOut
  );

  /// @notice swap with exact input
  /// @param swapCalldata calldata for multiple swaps
  /// @param tokenIn address of a token to swap on dex
  /// @param tokenOut address of a token to receive from dex
  /// @param amountIn exact amount of tokenIn to swap
  /// @param minAmountOut minimal amount of tokenOut to receive
  /// @param amountOut resulting amount of tokenOut output
  function swapExactInput(
    uint256 swapCalldata,
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut
  ) external returns (uint256 amountOut);

  /// @notice swap with exact output
  /// @param swapCalldata calldata for multiple swaps
  /// @param tokenIn address of a token to swap on dex
  /// @param tokenOut address of a token to receive from dex
  /// @param maxAmountIn maximal amount of tokenIn to swap
  /// @param amountOut exact amount of tokenOut to receive
  /// @param amountIn resulting amount of tokenIn input
  function swapExactOutput(
    uint256 swapCalldata,
    address tokenIn,
    address tokenOut,
    uint256 maxAmountIn,
    uint256 amountOut
  ) external returns (uint256 amountIn);

  /// @notice this function can be called by known adapters only
  /// @param recipient to whom transfer the tokens from swap initiator
  /// @param amount amount of tokens to transfer
  /// @param data callback data with transfer details and info to verify sender
  function adapterCallback(address recipient, uint256 amount, bytes calldata data) external;
}

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

enum CallType {
  DepositBase,
  DepositQuote,
  WithdrawBase,
  WithdrawQuote,
  Short,
  Long,
  ClosePosition,
  Reinit,
  ReceivePosition,
  EmergencyWithdraw
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

struct MarginlyParams {
  /// @dev Maximum allowable leverage in the Regular mode.
  uint8 maxLeverage;
  /// @dev Interest rate. Example 1% = 10000
  uint24 interestRate;
  /// @dev Close debt fee. 1% = 10000
  uint24 fee;
  /// @dev Pool fee. When users take leverage they pay `swapFee` on the notional borrow amount. 1% = 10000
  uint24 swapFee;
  /// @dev Max slippage when margin call
  uint24 mcSlippage;
  /// @dev Min amount of base token to open short/long position
  uint184 positionMinAmount;
  /// @dev Max amount of quote token in system
  uint184 quoteLimit;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

/// @dev Accrue interest doesn't happen in emergency mode.
/// @notice System mode. By default Regular, otherwise ShortEmergency/LongEmergency
enum Mode {
  Regular,
  /// Short positions collateral does not cover debt. All short positions get liquidated
  /// Long and lend positions should use emergencyWithdraw() to get back their tokens
  ShortEmergency,
  /// Long positions collateral does not enough to cover debt. All long positions get liquidated
  /// Short and lend positions should use emergencyWithdraw() to get back their tokens
  LongEmergency
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

enum PositionType {
  Uninitialized,
  Lend,
  Short,
  Long
}

/// @dev User's position in current pool
struct Position {
  /// @dev Type of a given position
  PositionType _type;
  /// @dev Position in heap equals indexOfHeap + 1. Zero value means position does not exist in heap
  uint32 heapPosition;
  /// @dev negative value if _type == Short, positive value otherwise in base asset (e.g. WETH)
  uint256 discountedBaseAmount;
  /// @dev negative value if _type == Long, positive value otherwise in quote asset (e.g. USDC)
  uint256 discountedQuoteAmount;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import '../dataTypes/MarginlyParams.sol';

interface IMarginlyFactory {
  /// @notice Emitted when a pool is created
  /// @param quoteToken The stable-coin
  /// @param baseToken The base token
  /// @param priceOracle Address of price oracle
  /// @param defaultSwapCallData Default swap call data for MC swaps
  /// @param pool The address of the created pool
  event PoolCreated(
    address indexed quoteToken,
    address indexed baseToken,
    address indexed priceOracle,
    uint32 defaultSwapCallData,
    address pool
  );

  /// @notice Emitted when changeSwapRouter was executed
  /// @param newSwapRouter new swap router address
  event SwapRouterChanged(address indexed newSwapRouter);

  /// @notice Creates a pool for the two given tokens and fee
  /// @param quoteToken One of the two tokens in the desired pool
  /// @param baseToken The other of the two tokens in the desired pool
  /// @param params pool parameters
  /// @param priceOracle price oracle to get base token price
  /// @param defaultSwapCallData default swap call data
  /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
  /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
  /// are invalid.
  /// @return pool The address of the newly created pool
  function createPool(
    address quoteToken,
    address baseToken,
    address priceOracle,
    uint32 defaultSwapCallData,
    MarginlyParams calldata params
  ) external returns (address pool);

  /// @notice Changes swap router address used by Marginly pools
  /// @param newSwapRouter address of new swap router
  function changeSwapRouter(address newSwapRouter) external;

  /// @notice Returns swapRouter
  function swapRouter() external view returns (address);

  /// @notice Swap fee holder address
  function feeHolder() external view returns (address);

  /// @notice Address of wrapper
  function WETH9() external view returns (address);

  /// @notice Address of technical position
  function techPositionOwner() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import './IMarginlyPoolOwnerActions.sol';
import '../dataTypes/Mode.sol';
import '../libraries/FP96.sol';
import '../dataTypes/Position.sol';
import '../dataTypes/Call.sol';

interface IMarginlyPool is IMarginlyPoolOwnerActions {
  /// @dev Emitted when margin call took place
  /// @param user User that was reinited
  /// @param swapPriceX96 Price of swap worth in quote token as Q96
  event EnactMarginCall(address indexed user, uint256 swapPriceX96);

  /// @dev Emitted when deleverage took place
  /// @param positionType deleveraged positions type
  /// @param totalCollateralReduced total collateral reduced from all positions
  /// @param totalDebtReduced total debt reduced from all positions
  event Deleverage(PositionType positionType, uint256 totalCollateralReduced, uint256 totalDebtReduced);

  /// @dev Emitted when user deposited base token
  /// @param user Depositor
  /// @param amount Amount of token user deposited
  /// @param newPositionType User position type after deposit
  /// @param baseDiscountedAmount Discounted amount of base tokens after deposit
  event DepositBase(address indexed user, uint256 amount, PositionType newPositionType, uint256 baseDiscountedAmount);

  /// @dev Emitted when user deposited quote token
  /// @param user Depositor
  /// @param amount Amount of token user deposited
  /// @param newPositionType User position type after deposit
  /// @param quoteDiscountedAmount Discounted amount of quote tokens after deposit
  event DepositQuote(address indexed user, uint256 amount, PositionType newPositionType, uint256 quoteDiscountedAmount);

  /// @dev Emitted when user withdrew base token
  /// @param user User
  /// @param amount Amount of token user withdrew
  /// @param baseDiscountedDelta Discounted delta amount of base tokens user withdrew
  event WithdrawBase(address indexed user, uint256 amount, uint256 baseDiscountedDelta);

  /// @dev Emitted when user withdrew quote token
  /// @param user User
  /// @param amount Amount of token user withdrew
  /// @param quoteDiscountedDelta Discounted delta amount of quote tokens user withdrew
  event WithdrawQuote(address indexed user, uint256 amount, uint256 quoteDiscountedDelta);

  /// @dev Emitted when user shorted
  /// @param user Depositor
  /// @param amount Amount of token user use in short position
  /// @param swapPriceX96 Price of swap worth in quote token as Q96
  /// @param quoteDiscountedDelta Discounted delta amount of quote tokens
  /// @param baseDiscountedDelta Discounted delta amount of base tokens
  event Short(
    address indexed user,
    uint256 amount,
    uint256 swapPriceX96,
    uint256 quoteDiscountedDelta,
    uint256 baseDiscountedDelta
  );

  /// @dev Emitted when user made long position
  /// @param user User
  /// @param amount Amount of token user use in long position
  /// @param swapPriceX96 Price of swap worth in quote token as Q96
  /// @param quoteDiscountedDelta Discounted delta amount of quote tokens
  /// @param baseDiscountedDelta Discounted delta amount of base tokens
  event Long(
    address indexed user,
    uint256 amount,
    uint256 swapPriceX96,
    uint256 quoteDiscountedDelta,
    uint256 baseDiscountedDelta
  );

  /// @dev Emitted when user sell all the base tokens from position before Short
  /// @param user User
  /// @param baseDelta amount of base token sold
  /// @param quoteDelta amount of quote tokens received
  /// @param discountedBaseCollateralDelta discounted delta amount of base tokens decreased collateral
  /// @param discountedQuoteCollateralDelta discounted amount of quote tokens increased collateral
  event SellBaseForQuote(
    address indexed user,
    uint256 baseDelta,
    uint256 quoteDelta,
    uint256 discountedBaseCollateralDelta,
    uint256 discountedQuoteCollateralDelta
  );

  /// @dev Emitted when user sell all the quote tokens from position before Long
  /// @param user User
  /// @param quoteDelta amount of quote tokens sold
  /// @param baseDelta amount of base token received
  /// @param discountedQuoteCollateralDelta discounted amount of quote tokens decreased collateral
  /// @param discountedBaseCollateralDelta discounted delta amount of base tokens increased collateral
  event SellQuoteForBase(
    address indexed user,
    uint256 quoteDelta,
    uint256 baseDelta,
    uint256 discountedQuoteCollateralDelta,
    uint256 discountedBaseCollateralDelta
  );

  /// @dev Emitted if long position sold base for quote
  /// @param user User
  /// @param realQuoteDebtDelta real value of quote debt repaid
  /// @param discountedQuoteDebtDelta discounted value of quote debt repaid
  event QuoteDebtRepaid(address indexed user, uint256 realQuoteDebtDelta, uint256 discountedQuoteDebtDelta);

  /// @dev Emitted if short position sold quote for base
  /// @param user User
  /// @param realBaseDebtDelta real value of base debt repaid
  /// @param discountedBaseDebtDelta discounted value of base debt repaid
  event BaseDebtRepaid(address indexed user, uint256 realBaseDebtDelta, uint256 discountedBaseDebtDelta);

  /// @dev Emitted when user closed position
  /// @param user User
  /// @param token Collateral token
  /// @param collateralDelta Amount of collateral reduction
  /// @param swapPriceX96 Price of swap worth in quote token as Q96
  /// @param collateralDiscountedDelta Amount of discounted collateral reduction
  event ClosePosition(
    address indexed user,
    address indexed token,
    uint256 collateralDelta,
    uint256 swapPriceX96,
    uint256 collateralDiscountedDelta
  );

  /// @dev Emitted when position liquidation happened
  /// @param liquidator Liquidator
  /// @param position Liquidated position
  /// @param newPositionType Type of tx sender new position
  /// @param newPositionQuoteDiscounted Discounted amount of quote tokens for new position
  /// @param newPositionBaseDiscounted Discounted amount of base tokens for new position
  event ReceivePosition(
    address indexed liquidator,
    address indexed position,
    PositionType newPositionType,
    uint256 newPositionQuoteDiscounted,
    uint256 newPositionBaseDiscounted
  );

  /// @dev When system switched to emergency mode
  /// @param mode Emergency mode
  event Emergency(Mode mode);

  /// @dev Emitted when user made emergency withdraw
  /// @param who Position owner
  /// @param token Token of withdraw
  /// @param amount Amount of withdraw
  event EmergencyWithdraw(address indexed who, address indexed token, uint256 amount);

  /// @dev Emitted when reinit happened
  /// @param reinitTimestamp timestamp when reinit happened
  event Reinit(uint256 reinitTimestamp);

  /// @dev Emitted when balance sync happened
  event BalanceSync();

  /// @dev Emitted when setParameters method was called
  event ParametersChanged();

  /// @dev Initializes the pool
  function initialize(
    address quoteToken,
    address baseToken,
    address priceOracle,
    uint32 defaultSwapCallData,
    MarginlyParams calldata params
  ) external;

  /// @notice Returns the address of quote token from pool
  function quoteToken() external view returns (address token);

  /// @notice Returns the address of base token from pool
  function baseToken() external view returns (address token);

  /// @notice Returns the address of price oracle
  function priceOracle() external view returns (address);

  /// @notice Returns default swap call data
  function defaultSwapCallData() external view returns (uint32);

  /// @notice Returns address of Marginly factory
  function factory() external view returns (address);

  /// @notice Return current value of base price used in all calculations (e.g. leverage)
  function getBasePrice() external view returns (FP96.FixedPoint memory);

  function execute(
    CallType call,
    uint256 amount1,
    int256 amount2,
    uint256 limitPriceX96,
    bool unwrapWETH,
    address receivePositionAddress,
    uint256 swapCalldata
  ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import '../dataTypes/MarginlyParams.sol';

interface IMarginlyPoolOwnerActions {
  /// @notice Sets the pool parameters. May only be called by the pool owner
  function setParameters(MarginlyParams calldata _params) external;

  /// @notice Switch to emergency mode when collateral of any side not enough to cover debt
  /// @param swapCalldata router calldata for splitting swap to reduce potential sandwich attacks impact
  function shutDown(uint256 swapCalldata) external;

  /// @notice Sweep ETH balance of contract
  function sweepETH() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

interface IPriceOracle {
  /// @notice Returns price as X96 value
  function getBalancePrice(address quoteToken, address baseToken) external view returns (uint256);

  /// @notice Returns margin call price as X96 value
  function getMargincallPrice(address quoteToken, address baseToken) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Errors {
  error AccessDenied();
  error ExceedsLimit();
  error EmergencyMode();
  error Forbidden();
  error LongEmergency();
  error Locked();
  error LessThanMinimalAmount();
  error BadLeverage();
  error NotLiquidatable();
  error NotOwner();
  error NotWETH9();
  error PoolAlreadyCreated();
  error PositionInitialized();
  error ShortEmergency();
  error SlippageLimit();
  error NotEmergency();
  error UninitializedPosition();
  error UniswapPoolNotFound();
  error UnknownCall();
  error WrongIndex();
  error WrongPositionType();
  error WrongValue();
  error ZeroAmount();
  error BigPrecisionLoss();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library FP48 {
  /// @dev Bits precision of FixedPoint number
  uint8 internal constant RESOLUTION = 48;
  /// @dev Denominator for FixedPoint number. 2^48
  uint96 internal constant Q48 = 0x1000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import '@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

import './Errors.sol';

library FP96 {
  /// @dev Bits precision of FixedPoint number
  uint8 internal constant RESOLUTION = 96;
  /// @dev Denominator for FixedPoint number
  uint256 internal constant Q96 = 0x1000000000000000000000000;
  /// @dev Represents Q96 number with half precision
  uint256 internal constant Q48 = 0x1000000000000;
  /// @dev Maximum value of FixedPoint number
  uint256 internal constant INNER_MAX = type(uint256).max;
  /// @dev Representation for FixedPoint number
  struct FixedPoint {
    uint256 inner;
  }

  /// @dev Returns one in FixedPoint representation
  function one() internal pure returns (FixedPoint memory result) {
    result.inner = Q96;
  }

  /// @dev Returns with  in FixedPoint representation
  function halfPrecision() internal pure returns (FixedPoint memory result) {
    result.inner = Q48;
  }

  /// @dev Returns zero in FixedPoint representation
  function zero() internal pure returns (FixedPoint memory result) {
    result.inner = uint256(0);
  }

  /// @dev Create FixedPoint number from ratio
  /// @param nom Ratio nominator
  /// @param den Ratio denominator
  /// @return result Ratio representation
  function fromRatio(uint256 nom, uint256 den) internal pure returns (FixedPoint memory result) {
    result.inner = Math.mulDiv(Q96, nom, den);
  }

  /// @notice Add two FixedPoint numbers
  /// @param self The augend
  /// @param other The addend
  /// @return result The sum of self and other
  function add(FixedPoint memory self, FixedPoint memory other) internal pure returns (FixedPoint memory result) {
    result.inner = LowGasSafeMath.add(self.inner, other.inner);
  }

  /// @notice Subtract two FixedPoint numbers
  /// @param self The minuend
  /// @param other The subtrahend
  /// @return result The difference of self and other
  function sub(FixedPoint memory self, FixedPoint memory other) internal pure returns (FixedPoint memory result) {
    result.inner = LowGasSafeMath.sub(self.inner, other.inner);
  }

  /// @notice Multiply two FixedPoint numbers
  /// @param self The multiplicand
  /// @param other The multiplier
  /// @return result The product of self and other
  function mul(FixedPoint memory self, FixedPoint memory other) internal pure returns (FixedPoint memory result) {
    result.inner = Math.mulDiv(self.inner, other.inner, Q96);
  }

  /// @notice Exponentiation base ^ exponent
  /// @param self The base
  /// @param exponent The exponent
  /// @return result The Exponentiation of self and rhs
  function pow(FixedPoint memory self, uint256 exponent) internal pure returns (FixedPoint memory result) {
    result = one();
    while (exponent > 0) {
      if (exponent & 1 == 1) {
        result = FP96.mul(result, self);
      }
      self = FP96.mul(self, self);
      exponent >>= 1;
    }
  }

  /// @notice Calculates (1 + x) ^ exponent using ${steps + 1} first terms of Taylor series
  /// @param self The base, must be 1 < self < 2
  /// @param exponent The exponent
  /// @return result The Exponentiation of self and rhs
  function powTaylor(FixedPoint memory self, uint256 exponent) internal pure returns (FixedPoint memory result) {
    uint256 x = self.inner - Q96;
    if (x >= Q96) revert Errors.WrongValue();

    uint256 resultX96 = Q96;
    uint256 multiplier;
    uint256 term = Q96;

    uint256 steps = exponent < 3 ? exponent : 3;
    unchecked {
      for (uint256 i; i != steps; ++i) {
        multiplier = ((exponent - i) * x) / (i + 1);
        term = (term * multiplier) / Q96;
        resultX96 += term;
      }
    }

    return FixedPoint({inner: resultX96});
  }

  /// @notice Divide two FixedPoint numbers
  /// @param self The dividend
  /// @param other The divisor
  /// @return result The quotient of self and other
  function div(FixedPoint memory self, FixedPoint memory other) internal pure returns (FixedPoint memory result) {
    result.inner = Math.mulDiv(self.inner, Q96, other.inner);
  }

  function eq(FixedPoint memory self, FixedPoint memory other) internal pure returns (bool) {
    return self.inner == other.inner;
  }

  function ne(FixedPoint memory self, FixedPoint memory other) internal pure returns (bool) {
    return self.inner != other.inner;
  }

  function lt(FixedPoint memory self, FixedPoint memory other) internal pure returns (bool) {
    return self.inner < other.inner;
  }

  function gt(FixedPoint memory self, FixedPoint memory other) internal pure returns (bool) {
    return self.inner > other.inner;
  }

  function le(FixedPoint memory self, FixedPoint memory other) internal pure returns (bool) {
    return self.inner <= other.inner;
  }

  function ge(FixedPoint memory self, FixedPoint memory other) internal pure returns (bool) {
    return self.inner >= other.inner;
  }

  /// @notice Calculates rhs * self
  /// @param self FixedPoint multiplier
  /// @param rhs Integer operand
  /// @return result Integer result
  function mul(FixedPoint memory self, uint256 rhs) internal pure returns (uint256 result) {
    result = Math.mulDiv(self.inner, rhs, Q96);
  }

  function mul(FixedPoint memory self, uint256 rhs, Math.Rounding rounding) internal pure returns (uint256 result) {
    result = Math.mulDiv(self.inner, rhs, Q96, rounding);
  }

  /// @notice Calculates rhs / self
  /// @param self FixedPoint divisor
  /// @param rhs Integer operand
  /// @return result Integer result
  function recipMul(FixedPoint memory self, uint256 rhs) internal pure returns (uint256 result) {
    result = Math.mulDiv(Q96, rhs, self.inner);
  }

  function recipMul(
    FixedPoint memory self,
    uint256 rhs,
    Math.Rounding rounding
  ) internal pure returns (uint256 result) {
    result = Math.mulDiv(Q96, rhs, self.inner, rounding);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '../dataTypes/Position.sol';
import './Errors.sol';

/// @title A Max-Heap implementation
/// @dev Implemented to use as embedded library. Invariant: key should be greater than zero
library MaxBinaryHeapLib {
  /// @dev Node structure to store key value and arbitrary data. 1 slot of data key 96 + address 160 = 256
  struct Node {
    /// @dev Stored as FixedPoint value with 10 bits for decimals
    uint96 key;
    /// @dev Account address
    address account;
  }

  /// @dev Heap representation. Using length and mapping instead of array reduce gas costs.
  struct Heap {
    /// @dev Keep heap elements by index
    mapping(uint32 => Node) nodes;
    /// @dev Total length of the Heap
    uint32 length;
  }

  /// @dev Inserting a new element into the heap. Time complexity O(Log n)
  /// @param self The heap
  /// @param node The node should be inserted into the heap
  /// @return index The index of inserted node
  function insert(
    Heap storage self,
    mapping(address => Position) storage positions,
    Node memory node
  ) internal returns (uint32) {
    uint32 index = self.length;
    self.nodes[index] = node;

    positions[node.account].heapPosition = index + 1;

    self.length = index + 1;
    return heapifyUp(self, positions, index);
  }

  /// @dev Update key value at index and change node position
  function update(
    Heap storage self,
    mapping(address => Position) storage positions,
    uint32 index,
    uint96 newKey
  ) internal returns (uint32 newIndex) {
    if (index >= self.length) revert Errors.WrongIndex();

    Node storage node = self.nodes[index];
    if (node.key < newKey) {
      node.key = newKey;
      newIndex = heapifyUp(self, positions, index);
    } else {
      node.key = newKey;
      newIndex = heapifyDown(self, positions, index);
    }
  }

  ///@dev Update account value of node
  function updateAccount(Heap storage self, uint32 index, address account) internal {
    self.nodes[index].account = account;
  }

  /// @dev Returns heap node by index
  function getNodeByIndex(Heap storage self, uint32 index) internal view returns (bool success, Node memory node) {
    if (index < self.length) {
      success = true;
      node = self.nodes[index];
    }
  }

  /// @dev Removes node by account
  function remove(Heap storage self, mapping(address => Position) storage positions, uint32 index) internal {
    uint32 length = self.length;
    if (index >= length) revert Errors.WrongIndex();

    uint32 last = length - 1;
    self.length = last;

    positions[self.nodes[index].account].heapPosition = 0;

    if (last != index) {
      uint96 oldKey = self.nodes[index].key;

      self.nodes[index] = self.nodes[last];
      positions[self.nodes[index].account].heapPosition = index + 1;

      if (oldKey < self.nodes[index].key) {
        heapifyUp(self, positions, index);
      } else {
        heapifyDown(self, positions, index);
      }
    }

    delete self.nodes[last];
  }

  /// @dev Swap two elements in the heap
  function swap(
    Heap storage self,
    mapping(address => Position) storage positions,
    uint32 first,
    uint32 second
  ) private {
    Node memory firstNode = self.nodes[first];
    Node memory secondNode = self.nodes[second];

    positions[firstNode.account].heapPosition = second + 1;
    positions[secondNode.account].heapPosition = first + 1;

    self.nodes[first] = secondNode;
    self.nodes[second] = firstNode;
  }

  /// @dev Traverse up starting from the `startIndex`
  function heapifyUp(
    Heap storage self,
    mapping(address => Position) storage positions,
    uint32 startIndex
  ) private returns (uint32) {
    uint32 index = startIndex;
    while (index != 0) {
      // optimized: "!= 0" costs less than "< 0" for unsigned
      uint32 parentIndex = (index - 1) >> 1;

      if (self.nodes[parentIndex].key >= self.nodes[index].key) {
        break;
      }

      swap(self, positions, index, parentIndex);
      index = parentIndex;
    }

    return index;
  }

  /// @dev Traverse down starting from the `startIndex`
  function heapifyDown(
    Heap storage self,
    mapping(address => Position) storage positions,
    uint32 startIndex
  ) private returns (uint32) {
    uint32 index = startIndex;
    uint32 length = self.length;

    while (true) {
      uint32 biggest = index;

      uint32 left = (index << 1) + 1;
      uint32 right = (index << 1) + 2;

      if (left < length) {
        // optimized: nested "if" costs less gas than combined
        if (self.nodes[left].key > self.nodes[biggest].key) {
          biggest = left;
        }
      }

      if (right < length) {
        // optimized: nested "if" costs less gas than combined
        if (self.nodes[right].key > self.nodes[biggest].key) {
          biggest = right;
        }
      }

      if (biggest == index) {
        break;
      }

      swap(self, positions, index, biggest);
      index = biggest;
    }

    return index;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLib {
  error T();
  error ZeroSeconds();

  /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
  int24 private constant MAX_TICK = 887272;

  /// @notice Calculates sqrt of TWAP price
  /// @param pool Address of the pool that we want to observe
  /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
  function getSqrtPriceX96(address pool, uint32 secondsAgo) internal view returns (uint256 priceX96) {
    if (secondsAgo == 0) revert ZeroSeconds();

    uint32[] memory secondsAgos = new uint32[](2);
    secondsAgos[0] = secondsAgo;
    secondsAgos[1] = 0;

    (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);
    int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

    int24 arithmeticMeanTick = int24(tickCumulativesDelta / int56(uint56(secondsAgo)));
    // Always round to negative infinity
    if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0)) arithmeticMeanTick--;
    priceX96 = getSqrtRatioAtTick(arithmeticMeanTick);
  }

  /// @notice Calculates sqrt(1.0001^tick) * 2^96
  /// @dev Throws if |tick| > max tick
  /// @dev Copied from uniswap v4 TickMath.sol https://github.com/Uniswap/v4-core/blob/eb61604467ae331259298585c290da85b46f6aaa/contracts/libraries/TickMath.sol
  /// same in KyberSwap https://github.com/KyberNetwork/ks-elastic-sc-legacy/blob/15175cc06ecc26df1d2f14df4e1e8286dfa79318/contracts/libraries/TickMath.sol
  /// @param tick The input tick for the above formula
  /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
  /// at the given tick
  function getSqrtRatioAtTick(int24 tick) private pure returns (uint160 sqrtPriceX96) {
    unchecked {
      uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
      if (absTick > uint256(int256(MAX_TICK))) revert T();

      uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
      if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
      if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
      if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
      if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
      if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
      if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
      if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
      if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
      if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
      if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
      if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
      if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
      if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
      if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
      if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
      if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
      if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
      if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
      if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

      if (tick > 0) ratio = type(uint256).max / ratio;

      // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
      // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
      // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
      sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import '@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

import '@openzeppelin/contracts/access/Ownable2Step.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '@marginly/router/contracts/interfaces/IMarginlyRouter.sol';

import './interfaces/IMarginlyPool.sol';
import './interfaces/IMarginlyFactory.sol';
import './interfaces/IWETH9.sol';
import './interfaces/IPriceOracle.sol';
import './dataTypes/MarginlyParams.sol';
import './dataTypes/Position.sol';
import './dataTypes/Mode.sol';
import './libraries/MaxBinaryHeapLib.sol';
import './libraries/OracleLib.sol';
import './libraries/FP48.sol';
import './libraries/FP96.sol';
import './libraries/Errors.sol';
import './dataTypes/Call.sol';

contract MarginlyPool is IMarginlyPool {
  using FP96 for FP96.FixedPoint;
  using MaxBinaryHeapLib for MaxBinaryHeapLib.Heap;
  using LowGasSafeMath for uint256;

  /// @dev FP96 inner value of count of seconds in year. Equal 365.25 * 24 * 60 * 60
  uint256 private constant SECONDS_IN_YEAR_X96 = 2500250661360148260042022567123353600;

  /// @dev Denominator of fee value
  uint24 private constant WHOLE_ONE = 1e6;

  /// @dev Min available leverage
  uint8 private constant MIN_LEVERAGE = 1;

  /// @inheritdoc IMarginlyPool
  address public override factory;

  /// @inheritdoc IMarginlyPool
  uint32 public override defaultSwapCallData;

  /// @inheritdoc IMarginlyPool
  address public override quoteToken;
  /// @inheritdoc IMarginlyPool
  address public override baseToken;
  /// @inheritdoc IMarginlyPool
  address public override priceOracle;
  /// @dev reentrancy guard
  bool private locked;

  Mode public mode;

  MarginlyParams public params;

  /// @dev Sum of all quote token in collateral
  uint256 public discountedQuoteCollateral;
  /// @dev Sum of all quote token in debt
  uint256 public discountedQuoteDebt;
  /// @dev Sum of  all base token collateral
  uint256 public discountedBaseCollateral;
  /// @dev Sum of all base token in debt
  uint256 public discountedBaseDebt;
  /// @dev Timestamp of last reinit execution
  uint256 public lastReinitTimestampSeconds;

  /// @dev Aggregate for base collateral time change calculations
  FP96.FixedPoint public baseCollateralCoeff;
  /// @dev Aggregate for deleveraged base collateral
  FP96.FixedPoint public baseDelevCoeff;
  /// @dev Aggregate for base debt time change calculations
  FP96.FixedPoint public baseDebtCoeff;
  /// @dev Aggregate for quote collateral time change calculations
  FP96.FixedPoint public quoteCollateralCoeff;
  /// @dev Aggregate for deleveraged quote collateral
  FP96.FixedPoint public quoteDelevCoeff;
  /// @dev Accrued interest rate and fee for quote debt
  FP96.FixedPoint public quoteDebtCoeff;
  /// @dev Initial price. Used to sort key and shutdown calculations. Value gets reset for the latter one
  FP96.FixedPoint public initialPrice;
  /// @dev Ratio of best side collaterals before and after margin call of opposite side in shutdown mode
  FP96.FixedPoint public emergencyWithdrawCoeff;

  struct Leverage {
    /// @dev This is a leverage of all long positions in the system
    uint128 shortX96;
    /// @dev This is a leverage of all short positions in the system
    uint128 longX96;
  }

  Leverage public systemLeverage;

  ///@dev Heap of short positions, root - the worst short position. Sort key - leverage calculated with discounted collateral, debt
  MaxBinaryHeapLib.Heap private shortHeap;
  ///@dev Heap of long positions, root - the worst long position. Sort key - leverage calculated with discounted collateral, debt
  MaxBinaryHeapLib.Heap private longHeap;

  /// @notice users positions
  mapping(address => Position) public positions;

  constructor() {
    factory = address(0xdead);
  }

  function _initializeMarginlyPool(
    address _quoteToken,
    address _baseToken,
    address _priceOracle,
    uint32 _defaultSwapCallData,
    MarginlyParams memory _params
  ) internal {
    if (_quoteToken == address(0)) revert Errors.WrongValue();
    if (_baseToken == address(0)) revert Errors.WrongValue();
    if (_priceOracle == address(0)) revert Errors.WrongValue();

    factory = msg.sender;
    quoteToken = _quoteToken;
    baseToken = _baseToken;
    priceOracle = _priceOracle;
    _setParameters(_params);

    baseCollateralCoeff = FP96.one();
    baseDebtCoeff = FP96.one();
    quoteCollateralCoeff = FP96.one();
    quoteDebtCoeff = FP96.one();
    lastReinitTimestampSeconds = getTimestamp();
    initialPrice = getBasePrice();
    defaultSwapCallData = _defaultSwapCallData;

    Position storage techPosition = getTechPosition();
    techPosition._type = PositionType.Lend;
  }

  /// @inheritdoc IMarginlyPool
  function initialize(
    address _quoteToken,
    address _baseToken,
    address _priceOracle,
    uint32 _defaultSwapCallData,
    MarginlyParams calldata _params
  ) external virtual {
    if (factory != address(0)) revert Errors.Forbidden();

    _initializeMarginlyPool(_quoteToken, _baseToken, _priceOracle, _defaultSwapCallData, _params);
  }

  receive() external payable {
    if (msg.sender != getWETH9Address()) revert Errors.NotWETH9();
  }

  function _lock() private view {
    if (locked) revert Errors.Locked();
  }

  /// @dev Protects against reentrancy
  modifier lock() {
    _lock();
    locked = true;
    _;
    delete locked;
  }

  function _onlyFactoryOwner() private view {
    if (msg.sender != Ownable2Step(factory).owner()) revert Errors.AccessDenied();
  }

  modifier onlyFactoryOwner() {
    _onlyFactoryOwner();
    _;
  }

  /// @inheritdoc IMarginlyPoolOwnerActions
  function setParameters(MarginlyParams calldata _params) external override onlyFactoryOwner {
    _setParameters(_params);
  }

  function _setParameters(MarginlyParams memory _params) private {
    if (
      _params.interestRate > WHOLE_ONE ||
      _params.fee > WHOLE_ONE ||
      _params.swapFee > WHOLE_ONE ||
      _params.mcSlippage > WHOLE_ONE ||
      _params.maxLeverage < MIN_LEVERAGE ||
      _params.quoteLimit == 0 ||
      _params.positionMinAmount == 0
    ) revert Errors.WrongValue();

    params = _params;
    emit ParametersChanged();
  }

  /// @dev Swaps tokens to receive exact amountOut and send at most amountInMaximum
  function swapExactOutput(
    bool quoteIn,
    uint256 amountInMaximum,
    uint256 amountOut,
    uint256 swapCalldata
  ) private returns (uint256 amountInActual) {
    address swapRouter = getSwapRouter();
    (address tokenIn, address tokenOut) = quoteIn ? (quoteToken, baseToken) : (baseToken, quoteToken);

    SafeERC20.forceApprove(IERC20(tokenIn), swapRouter, amountInMaximum);

    amountInActual = IMarginlyRouter(swapRouter).swapExactOutput(
      swapCalldata,
      tokenIn,
      tokenOut,
      amountInMaximum,
      amountOut
    );

    SafeERC20.forceApprove(IERC20(tokenIn), swapRouter, 0);
  }

  /// @dev Swaps tokens to spend exact amountIn and receive at least amountOutMinimum
  function swapExactInput(
    bool quoteIn,
    uint256 amountIn,
    uint256 amountOutMinimum,
    uint256 swapCalldata
  ) private returns (uint256 amountOutActual) {
    address swapRouter = getSwapRouter();
    (address tokenIn, address tokenOut) = quoteIn ? (quoteToken, baseToken) : (baseToken, quoteToken);

    SafeERC20.forceApprove(IERC20(tokenIn), swapRouter, amountIn);

    amountOutActual = IMarginlyRouter(swapRouter).swapExactInput(
      swapCalldata,
      tokenIn,
      tokenOut,
      amountIn,
      amountOutMinimum
    );
  }

  /// @dev User liquidation: applies deleverage if needed then enacts MC
  /// @param user User's address
  /// @param position User's position to reinit
  function liquidate(address user, Position storage position, FP96.FixedPoint memory basePrice) private {
    if (position._type == PositionType.Short) {
      uint256 realQuoteCollateral = calcRealQuoteCollateral(
        position.discountedQuoteAmount,
        position.discountedBaseAmount
      );

      // positionRealQuoteCollateral > poolQuoteBalance = poolQuoteCollateral - poolQuoteDebt
      // positionRealQuoteCollateral + poolQuoteDebt > poolQuoteCollateral
      uint256 poolQuoteCollateral = calcRealQuoteCollateral(discountedQuoteCollateral, discountedBaseDebt);
      uint256 posQuoteCollPlusPoolQuoteDebt = quoteDebtCoeff.mul(discountedQuoteDebt).add(realQuoteCollateral);

      if (posQuoteCollPlusPoolQuoteDebt > poolQuoteCollateral) {
        // quoteDebtToReduce = positionRealQuoteCollateral - (poolQuoteCollateral - poolQuoteDebt) =
        // = (positionRealQuoteCollateral + poolQuoteDebt) - poolQuoteCollateral
        uint256 quoteDebtToReduce = posQuoteCollPlusPoolQuoteDebt.sub(poolQuoteCollateral);
        uint256 baseCollToReduce = basePrice.recipMul(quoteDebtToReduce);
        uint256 positionBaseDebt = baseDebtCoeff.mul(position.discountedBaseAmount);
        if (baseCollToReduce > positionBaseDebt) {
          baseCollToReduce = positionBaseDebt;
        }
        deleverageLong(baseCollToReduce, quoteDebtToReduce);

        uint256 disBaseDelta = baseDebtCoeff.recipMul(baseCollToReduce);
        position.discountedBaseAmount = position.discountedBaseAmount.sub(disBaseDelta);
        discountedBaseDebt = discountedBaseDebt.sub(disBaseDelta);

        uint256 disQuoteDelta = quoteCollateralCoeff.recipMul(quoteDebtToReduce.add(quoteDelevCoeff.mul(disBaseDelta)));
        position.discountedQuoteAmount = position.discountedQuoteAmount.sub(disQuoteDelta);
        discountedQuoteCollateral = discountedQuoteCollateral.sub(disQuoteDelta);
      }
    } else if (position._type == PositionType.Long) {
      uint256 realBaseCollateral = calcRealBaseCollateral(
        position.discountedBaseAmount,
        position.discountedQuoteAmount
      );

      // positionRealBaseCollateral > poolBaseBalance = poolBaseCollateral - poolBaseDebt
      // positionRealBaseCollateral + poolBaseDebt > poolBaseCollateral
      uint256 poolBaseCollateral = calcRealBaseCollateral(discountedBaseCollateral, discountedQuoteDebt);
      uint256 posBaseCollPlusPoolBaseDebt = baseDebtCoeff.mul(discountedBaseDebt).add(realBaseCollateral);

      if (posBaseCollPlusPoolBaseDebt > poolBaseCollateral) {
        // baseDebtToReduce = positionRealBaseCollateral - (poolBaseCollateral - poolBaseDebt) =
        // = (positionRealBaseCollateral + poolBaseDebt) - poolBaseCollateral
        uint256 baseDebtToReduce = posBaseCollPlusPoolBaseDebt.sub(poolBaseCollateral);
        uint256 quoteCollToReduce = basePrice.mul(baseDebtToReduce);
        uint256 positionQuoteDebt = quoteDebtCoeff.mul(position.discountedQuoteAmount);
        if (quoteCollToReduce > positionQuoteDebt) {
          quoteCollToReduce = positionQuoteDebt;
        }
        deleverageShort(quoteCollToReduce, baseDebtToReduce);

        uint256 disQuoteDelta = quoteDebtCoeff.recipMul(quoteCollToReduce);
        position.discountedQuoteAmount = position.discountedQuoteAmount.sub(disQuoteDelta);
        discountedQuoteDebt = discountedQuoteDebt.sub(disQuoteDelta);

        uint256 disBaseDelta = baseCollateralCoeff.recipMul(baseDebtToReduce.add(baseDelevCoeff.mul(disQuoteDelta)));
        position.discountedBaseAmount = position.discountedBaseAmount.sub(disBaseDelta);
        discountedBaseCollateral = discountedBaseCollateral.sub(disBaseDelta);
      }
    } else {
      revert Errors.WrongPositionType();
    }
    enactMarginCall(user, position);
  }

  /// @dev All short positions deleverage
  /// @param realQuoteCollateral Total quote collateral to reduce on all short positions
  /// @param realBaseDebt Total base debt to reduce on all short positions
  function deleverageShort(uint256 realQuoteCollateral, uint256 realBaseDebt) private {
    quoteDelevCoeff = quoteDelevCoeff.add(FP96.fromRatio(realQuoteCollateral, discountedBaseDebt));
    baseDebtCoeff = baseDebtCoeff.sub(FP96.fromRatio(realBaseDebt, discountedBaseDebt));

    // this error is highly unlikely to occur and requires lots of big whales liquidations prior to it
    // however if it happens, the ways to fix what seems like a pool deadlock are 'receivePosition' and 'balanceSync'
    if (baseDebtCoeff.inner < FP96.halfPrecision().inner) revert Errors.BigPrecisionLoss();

    emit Deleverage(PositionType.Short, realQuoteCollateral, realBaseDebt);
  }

  /// @dev All long positions deleverage
  /// @param realBaseCollateral Total base collateral to reduce on all long positions
  /// @param realQuoteDebt Total quote debt to reduce on all long positions
  function deleverageLong(uint256 realBaseCollateral, uint256 realQuoteDebt) private {
    baseDelevCoeff = baseDelevCoeff.add(FP96.fromRatio(realBaseCollateral, discountedQuoteDebt));
    quoteDebtCoeff = quoteDebtCoeff.sub(FP96.fromRatio(realQuoteDebt, discountedQuoteDebt));

    // this error is highly unlikely to occur and requires lots of big whales liquidations prior to it
    // however if it happens, the ways to fix what seems like a pool deadlock are 'receivePosition' and 'balanceSync'
    if (quoteDebtCoeff.inner < FP96.halfPrecision().inner) revert Errors.BigPrecisionLoss();

    emit Deleverage(PositionType.Long, realBaseCollateral, realQuoteDebt);
  }

  /// @dev Enact margin call procedure for the position
  /// @param user User's address
  /// @param position User's position to reinit
  function enactMarginCall(address user, Position storage position) private {
    uint256 swapPriceX96;
    // it's guaranteed by liquidate() function, that position._type is either Short or Long
    // else is used to save some contract space
    if (position._type == PositionType.Short) {
      uint256 realQuoteCollateral = calcRealQuoteCollateral(
        position.discountedQuoteAmount,
        position.discountedBaseAmount
      );
      uint256 realBaseDebt = baseDebtCoeff.mul(position.discountedBaseAmount);

      // short position mc
      uint256 swappedBaseDebt;
      if (realQuoteCollateral != 0) {
        uint baseOutMinimum = FP96.fromRatio(WHOLE_ONE - params.mcSlippage, WHOLE_ONE).mul(
          getLiquidationPrice().recipMul(realQuoteCollateral)
        );
        swappedBaseDebt = swapExactInput(true, realQuoteCollateral, baseOutMinimum, defaultSwapCallData);
        swapPriceX96 = getSwapPrice(realQuoteCollateral, swappedBaseDebt);
      }

      FP96.FixedPoint memory factor;
      // baseCollateralCoeff += rcd * (rqc - sqc) / sqc
      if (swappedBaseDebt >= realBaseDebt) {
        // Position has enough collateral to repay debt
        factor = FP96.one().add(
          FP96.fromRatio(
            swappedBaseDebt.sub(realBaseDebt),
            calcRealBaseCollateral(discountedBaseCollateral, discountedQuoteDebt)
          )
        );
      } else {
        // Position's debt has been repaid by pool
        factor = FP96.one().sub(
          FP96.fromRatio(
            realBaseDebt.sub(swappedBaseDebt),
            calcRealBaseCollateral(discountedBaseCollateral, discountedQuoteDebt)
          )
        );
      }
      updateBaseCollateralCoeffs(factor);

      discountedQuoteCollateral = discountedQuoteCollateral.sub(position.discountedQuoteAmount);
      discountedBaseDebt = discountedBaseDebt.sub(position.discountedBaseAmount);

      //remove position
      shortHeap.remove(positions, position.heapPosition - 1);
    } else {
      uint256 realBaseCollateral = calcRealBaseCollateral(
        position.discountedBaseAmount,
        position.discountedQuoteAmount
      );
      uint256 realQuoteDebt = quoteDebtCoeff.mul(position.discountedQuoteAmount);

      // long position mc
      uint256 swappedQuoteDebt;
      if (realBaseCollateral != 0) {
        uint256 quoteOutMinimum = FP96.fromRatio(WHOLE_ONE - params.mcSlippage, WHOLE_ONE).mul(
          getLiquidationPrice().mul(realBaseCollateral)
        );
        swappedQuoteDebt = swapExactInput(false, realBaseCollateral, quoteOutMinimum, defaultSwapCallData);
        swapPriceX96 = getSwapPrice(swappedQuoteDebt, realBaseCollateral);
      }

      FP96.FixedPoint memory factor;
      // quoteCollateralCoef += rqd * (rbc - sbc) / sbc
      if (swappedQuoteDebt >= realQuoteDebt) {
        // Position has enough collateral to repay debt
        factor = FP96.one().add(
          FP96.fromRatio(
            swappedQuoteDebt.sub(realQuoteDebt),
            calcRealQuoteCollateral(discountedQuoteCollateral, discountedBaseDebt)
          )
        );
      } else {
        // Position's debt has been repaid by pool
        factor = FP96.one().sub(
          FP96.fromRatio(
            realQuoteDebt.sub(swappedQuoteDebt),
            calcRealQuoteCollateral(discountedQuoteCollateral, discountedBaseDebt)
          )
        );
      }
      updateQuoteCollateralCoeffs(factor);

      discountedBaseCollateral = discountedBaseCollateral.sub(position.discountedBaseAmount);
      discountedQuoteDebt = discountedQuoteDebt.sub(position.discountedQuoteAmount);

      //remove position
      longHeap.remove(positions, position.heapPosition - 1);
    }

    delete positions[user];
    emit EnactMarginCall(user, swapPriceX96);
  }

  /// @dev Calculate leverage
  function calcLeverage(uint256 collateral, uint256 debt) private pure returns (uint256 leverage) {
    if (collateral > debt) {
      return Math.mulDiv(FP96.Q96, collateral, collateral - debt);
    } else {
      return FP96.INNER_MAX;
    }
  }

  /// @dev Calculate sort key for ordering long/short positions.
  /// Sort key represents value of debt / collateral both in quoteToken.
  /// as FixedPoint with 10 bits for decimals
  function calcSortKey(uint256 collateral, uint256 debt) private pure returns (uint96) {
    uint96 maxValue = type(uint96).max;
    if (collateral != 0) {
      uint256 result = Math.mulDiv(FP48.Q48, debt, collateral);
      if (result > maxValue) {
        return maxValue;
      } else {
        return uint96(result);
      }
    } else {
      return maxValue;
    }
  }

  /// @notice Deposit base token
  /// @param amount Amount of base token to deposit
  /// @param basePrice current oracle base price, got by getBasePrice() method
  /// @param position msg.sender position
  function depositBase(uint256 amount, FP96.FixedPoint memory basePrice, Position storage position) private {
    if (amount == 0) revert Errors.ZeroAmount();

    if (position._type == PositionType.Uninitialized) {
      position._type = PositionType.Lend;
    }

    FP96.FixedPoint memory _baseDebtCoeff = baseDebtCoeff;

    uint256 positionDiscountedBaseAmountPrev = position.discountedBaseAmount;
    if (position._type == PositionType.Short) {
      uint256 realBaseDebt = _baseDebtCoeff.mul(positionDiscountedBaseAmountPrev);
      uint256 discountedBaseDebtDelta;

      if (amount >= realBaseDebt) {
        uint256 newRealBaseCollateral = amount.sub(realBaseDebt);
        if (amount != realBaseDebt)
          if (basePrice.mul(newPoolBaseBalance(newRealBaseCollateral)) > params.quoteLimit)
            revert Errors.ExceedsLimit();

        shortHeap.remove(positions, position.heapPosition - 1);
        // Short position debt <= depositAmount, increase collateral on delta, change position to Lend
        // discountedBaseCollateralDelta = (amount - realDebt)/ baseCollateralCoeff
        uint256 discountedBaseCollateralDelta = baseCollateralCoeff.recipMul(newRealBaseCollateral);
        discountedBaseDebtDelta = positionDiscountedBaseAmountPrev;
        position._type = PositionType.Lend;
        position.discountedBaseAmount = discountedBaseCollateralDelta;

        // update aggregates
        discountedBaseCollateral = discountedBaseCollateral.add(discountedBaseCollateralDelta);
      } else {
        // Short position, debt > depositAmount, decrease debt
        discountedBaseDebtDelta = _baseDebtCoeff.recipMul(amount);
        position.discountedBaseAmount = positionDiscountedBaseAmountPrev.sub(discountedBaseDebtDelta);
      }

      uint256 discountedQuoteCollDelta = quoteCollateralCoeff.recipMul(quoteDelevCoeff.mul(discountedBaseDebtDelta));
      position.discountedQuoteAmount = position.discountedQuoteAmount.sub(discountedQuoteCollDelta);
      discountedBaseDebt = discountedBaseDebt.sub(discountedBaseDebtDelta);
      discountedQuoteCollateral = discountedQuoteCollateral.sub(discountedQuoteCollDelta);
    } else {
      if (basePrice.mul(newPoolBaseBalance(amount)) > params.quoteLimit) revert Errors.ExceedsLimit();

      // Lend position, increase collateral on amount
      // discountedCollateralDelta = amount / baseCollateralCoeff
      uint256 discountedCollateralDelta = baseCollateralCoeff.recipMul(amount);
      position.discountedBaseAmount = positionDiscountedBaseAmountPrev.add(discountedCollateralDelta);

      // update aggregates
      discountedBaseCollateral = discountedBaseCollateral.add(discountedCollateralDelta);
    }

    wrapAndTransferFrom(baseToken, msg.sender, amount);
    emit DepositBase(msg.sender, amount, position._type, position.discountedBaseAmount);
  }

  /// @notice Deposit quote token
  /// @param amount Amount of quote token
  /// @param position msg.sender position
  function depositQuote(uint256 amount, Position storage position) private {
    if (amount == 0) revert Errors.ZeroAmount();

    if (position._type == PositionType.Uninitialized) {
      position._type = PositionType.Lend;
    }

    FP96.FixedPoint memory _quoteDebtCoeff = quoteDebtCoeff;

    uint256 positionDiscountedQuoteAmountPrev = position.discountedQuoteAmount;
    if (position._type == PositionType.Long) {
      uint256 realQuoteDebt = _quoteDebtCoeff.mul(positionDiscountedQuoteAmountPrev);
      uint256 discountedQuoteDebtDelta;

      if (amount >= realQuoteDebt) {
        uint256 newRealQuoteCollateral = amount.sub(realQuoteDebt);
        if (amount != realQuoteDebt)
          if (newPoolQuoteBalance(newRealQuoteCollateral) > params.quoteLimit) revert Errors.ExceedsLimit();

        longHeap.remove(positions, position.heapPosition - 1);
        // Long position, debt <= depositAmount, increase collateral on delta, move position to Lend
        // quoteCollateralChange = (amount - discountedDebt)/ quoteCollateralCoef
        uint256 discountedQuoteCollateralDelta = quoteCollateralCoeff.recipMul(newRealQuoteCollateral);
        discountedQuoteDebtDelta = positionDiscountedQuoteAmountPrev;
        position._type = PositionType.Lend;
        position.discountedQuoteAmount = discountedQuoteCollateralDelta;

        // update aggregates
        discountedQuoteCollateral = discountedQuoteCollateral.add(discountedQuoteCollateralDelta);
      } else {
        // Long position, debt > depositAmount, decrease debt on delta
        discountedQuoteDebtDelta = _quoteDebtCoeff.recipMul(amount);
        position.discountedQuoteAmount = positionDiscountedQuoteAmountPrev.sub(discountedQuoteDebtDelta);
      }

      uint256 discountedBaseCollDelta = baseCollateralCoeff.recipMul(baseDelevCoeff.mul(discountedQuoteDebtDelta));
      position.discountedBaseAmount = position.discountedBaseAmount.sub(discountedBaseCollDelta);
      discountedQuoteDebt = discountedQuoteDebt.sub(discountedQuoteDebtDelta);
      discountedBaseCollateral = discountedBaseCollateral.sub(discountedBaseCollDelta);
    } else {
      if (newPoolQuoteBalance(amount) > params.quoteLimit) revert Errors.ExceedsLimit();

      // Lend position, increase collateral on amount
      // discountedQuoteCollateralDelta = amount / quoteCollateralCoeff
      uint256 discountedQuoteCollateralDelta = quoteCollateralCoeff.recipMul(amount);
      position.discountedQuoteAmount = positionDiscountedQuoteAmountPrev.add(discountedQuoteCollateralDelta);

      // update aggregates
      discountedQuoteCollateral = discountedQuoteCollateral.add(discountedQuoteCollateralDelta);
    }

    wrapAndTransferFrom(quoteToken, msg.sender, amount);
    emit DepositQuote(msg.sender, amount, position._type, position.discountedQuoteAmount);
  }

  /// @notice Withdraw base token
  /// @param realAmount Amount of base token
  /// @param unwrapWETH flag to unwrap WETH to ETH
  /// @param basePrice current oracle base price, got by getBasePrice() method
  /// @param position msg.sender position
  function withdrawBase(
    uint256 realAmount,
    bool unwrapWETH,
    FP96.FixedPoint memory basePrice,
    Position storage position
  ) private {
    if (realAmount == 0) revert Errors.ZeroAmount();

    PositionType _type = position._type;
    if (_type == PositionType.Uninitialized) revert Errors.UninitializedPosition();
    if (_type == PositionType.Short) revert Errors.WrongPositionType();

    uint256 positionBaseAmount = position.discountedBaseAmount;
    uint256 positionQuoteDebt = _type == PositionType.Lend ? 0 : position.discountedQuoteAmount;

    uint256 realBaseAmount = calcRealBaseCollateral(positionBaseAmount, positionQuoteDebt);
    uint256 realAmountToWithdraw;
    bool needToDeletePosition = false;
    uint256 discountedBaseCollateralDelta;
    if (realAmount >= realBaseAmount) {
      // full withdraw
      realAmountToWithdraw = realBaseAmount;
      discountedBaseCollateralDelta = positionBaseAmount;

      needToDeletePosition = position.discountedQuoteAmount == 0;
    } else {
      // partial withdraw
      realAmountToWithdraw = realAmount;
      discountedBaseCollateralDelta = baseCollateralCoeff.recipMul(realAmountToWithdraw);
    }

    if (_type == PositionType.Long) {
      uint256 realQuoteDebt = quoteDebtCoeff.mul(positionQuoteDebt);
      // margin = (baseColl - baseCollDelta) - quoteDebt / price < minAmount
      // minAmount + quoteDebt / price > baseColl - baseCollDelta
      if (basePrice.recipMul(realQuoteDebt).add(params.positionMinAmount) > realBaseAmount.sub(realAmountToWithdraw)) {
        revert Errors.LessThanMinimalAmount();
      }
    }

    position.discountedBaseAmount = positionBaseAmount.sub(discountedBaseCollateralDelta);
    discountedBaseCollateral = discountedBaseCollateral.sub(discountedBaseCollateralDelta);

    if (positionHasBadLeverage(position, basePrice)) revert Errors.BadLeverage();

    if (needToDeletePosition) {
      delete positions[msg.sender];
    }

    unwrapAndTransfer(unwrapWETH, baseToken, msg.sender, realAmountToWithdraw);

    emit WithdrawBase(msg.sender, realAmountToWithdraw, discountedBaseCollateralDelta);
  }

  /// @notice Withdraw quote token
  /// @param realAmount Amount of quote token
  /// @param unwrapWETH flag to unwrap WETH to ETH
  /// @param basePrice current oracle base price, got by getBasePrice() method
  /// @param position msg.sender position
  function withdrawQuote(
    uint256 realAmount,
    bool unwrapWETH,
    FP96.FixedPoint memory basePrice,
    Position storage position
  ) private {
    if (realAmount == 0) revert Errors.ZeroAmount();

    PositionType _type = position._type;
    if (_type == PositionType.Uninitialized) revert Errors.UninitializedPosition();
    if (_type == PositionType.Long) revert Errors.WrongPositionType();

    uint256 positionQuoteAmount = position.discountedQuoteAmount;
    uint256 positionBaseDebt = _type == PositionType.Lend ? 0 : position.discountedBaseAmount;

    uint256 realQuoteAmount = calcRealQuoteCollateral(positionQuoteAmount, positionBaseDebt);
    uint256 realAmountToWithdraw;
    bool needToDeletePosition = false;
    uint256 discountedQuoteCollateralDelta;
    if (realAmount >= realQuoteAmount) {
      // full withdraw
      realAmountToWithdraw = realQuoteAmount;
      discountedQuoteCollateralDelta = positionQuoteAmount;

      needToDeletePosition = position.discountedBaseAmount == 0;
    } else {
      // partial withdraw
      realAmountToWithdraw = realAmount;
      discountedQuoteCollateralDelta = quoteCollateralCoeff.recipMul(realAmountToWithdraw);
    }

    if (_type == PositionType.Short) {
      uint256 realBaseDebt = baseDebtCoeff.mul(positionBaseDebt);
      // margin = (quoteColl - quoteCollDelta) - baseDebt * price < minAmount * price
      // (minAmount + baseDebt) * price > quoteColl - quoteCollDelta
      if (basePrice.mul(realBaseDebt.add(params.positionMinAmount)) > realQuoteAmount.sub(realAmountToWithdraw)) {
        revert Errors.LessThanMinimalAmount();
      }
    }

    position.discountedQuoteAmount = positionQuoteAmount.sub(discountedQuoteCollateralDelta);
    discountedQuoteCollateral = discountedQuoteCollateral.sub(discountedQuoteCollateralDelta);

    if (positionHasBadLeverage(position, basePrice)) revert Errors.BadLeverage();

    if (needToDeletePosition) {
      delete positions[msg.sender];
    }

    unwrapAndTransfer(unwrapWETH, quoteToken, msg.sender, realAmountToWithdraw);

    emit WithdrawQuote(msg.sender, realAmountToWithdraw, discountedQuoteCollateralDelta);
  }

  /// @notice Close position
  /// @param position msg.sender position
  function closePosition(uint256 limitPriceX96, Position storage position, uint256 swapCalldata) private {
    uint256 realCollateralDelta;
    uint256 discountedCollateralDelta;
    address collateralToken;
    uint256 swapPriceX96;
    if (position._type == PositionType.Short) {
      collateralToken = quoteToken;

      uint256 positionDiscountedBaseDebtPrev = position.discountedBaseAmount;
      uint256 realQuoteCollateral = calcRealQuoteCollateral(
        position.discountedQuoteAmount,
        position.discountedBaseAmount
      );
      uint256 realBaseDebt = baseDebtCoeff.mul(positionDiscountedBaseDebtPrev, Math.Rounding.Up);

      {
        // quoteInMaximum is defined by user input limitPriceX96
        uint256 quoteInMaximum = Math.mulDiv(limitPriceX96, realBaseDebt, FP96.Q96);

        realCollateralDelta = swapExactOutput(true, realQuoteCollateral, realBaseDebt, swapCalldata);
        if (realCollateralDelta > quoteInMaximum) revert Errors.SlippageLimit();
        swapPriceX96 = getSwapPrice(realCollateralDelta, realBaseDebt);

        uint256 realFeeAmount = Math.mulDiv(params.swapFee, realCollateralDelta, WHOLE_ONE);
        chargeFee(realFeeAmount);

        realCollateralDelta = realCollateralDelta.add(realFeeAmount);
        discountedCollateralDelta = quoteCollateralCoeff.recipMul(
          realCollateralDelta.add(quoteDelevCoeff.mul(position.discountedBaseAmount))
        );
      }

      discountedQuoteCollateral = discountedQuoteCollateral.sub(discountedCollateralDelta);
      discountedBaseDebt = discountedBaseDebt.sub(positionDiscountedBaseDebtPrev);

      position.discountedQuoteAmount = position.discountedQuoteAmount.sub(discountedCollateralDelta);
      position.discountedBaseAmount = 0;
      position._type = PositionType.Lend;

      uint32 heapIndex = position.heapPosition - 1;
      shortHeap.remove(positions, heapIndex);
    } else if (position._type == PositionType.Long) {
      collateralToken = baseToken;

      uint256 positionDiscountedQuoteDebtPrev = position.discountedQuoteAmount;
      uint256 realBaseCollateral = calcRealBaseCollateral(
        position.discountedBaseAmount,
        position.discountedQuoteAmount
      );
      uint256 realQuoteDebt = quoteDebtCoeff.mul(positionDiscountedQuoteDebtPrev, Math.Rounding.Up);

      uint256 realFeeAmount = Math.mulDiv(params.swapFee, realQuoteDebt, WHOLE_ONE);
      uint256 exactQuoteOut = realQuoteDebt.add(realFeeAmount);

      {
        // baseInMaximum is defined by user input limitPriceX96
        uint256 baseInMaximum = Math.mulDiv(FP96.Q96, exactQuoteOut, limitPriceX96);

        realCollateralDelta = swapExactOutput(false, realBaseCollateral, exactQuoteOut, swapCalldata);
        if (realCollateralDelta > baseInMaximum) revert Errors.SlippageLimit();
        swapPriceX96 = getSwapPrice(exactQuoteOut, realCollateralDelta);

        chargeFee(realFeeAmount);

        discountedCollateralDelta = baseCollateralCoeff.recipMul(
          realCollateralDelta.add(baseDelevCoeff.mul(position.discountedQuoteAmount))
        );
      }

      discountedBaseCollateral = discountedBaseCollateral.sub(discountedCollateralDelta);
      discountedQuoteDebt = discountedQuoteDebt.sub(positionDiscountedQuoteDebtPrev);

      position.discountedBaseAmount = position.discountedBaseAmount.sub(discountedCollateralDelta);
      position.discountedQuoteAmount = 0;
      position._type = PositionType.Lend;

      uint32 heapIndex = position.heapPosition - 1;
      longHeap.remove(positions, heapIndex);
    } else {
      revert Errors.WrongPositionType();
    }

    emit ClosePosition(msg.sender, collateralToken, realCollateralDelta, swapPriceX96, discountedCollateralDelta);
  }

  /// @dev Charge fee (swap or debt fee) in quote token
  /// @param feeAmount amount of token
  function chargeFee(uint256 feeAmount) private {
    TransferHelper.safeTransfer(quoteToken, IMarginlyFactory(factory).feeHolder(), feeAmount);
  }

  /// @notice Get oracle price baseToken / quoteToken
  function getBasePrice() public view returns (FP96.FixedPoint memory) {
    uint256 price = IPriceOracle(priceOracle).getBalancePrice(quoteToken, baseToken);
    return FP96.FixedPoint({inner: price});
  }

  /// @notice Get TWAP price used in mc slippage calculations
  function getLiquidationPrice() public view returns (FP96.FixedPoint memory) {
    uint256 price = IPriceOracle(priceOracle).getMargincallPrice(quoteToken, baseToken);
    return FP96.FixedPoint({inner: price});
  }

  /// @notice Short with leverage
  /// @param realBaseAmount Amount of base token
  /// @param basePrice current oracle base price, got by getBasePrice() method
  /// @param position msg.sender position
  function short(
    uint256 realBaseAmount,
    uint256 limitPriceX96,
    FP96.FixedPoint memory basePrice,
    Position storage position,
    uint256 swapCalldata
  ) private {
    revert Errors.Forbidden();
    // this function guaranties the position is gonna be either Short or Lend with 0 base balance
    sellBaseForQuote(position, limitPriceX96, swapCalldata);

    uint256 positionDisBaseDebt = position.discountedBaseAmount;
    uint256 positionDisQuoteCollateral = position.discountedQuoteAmount;

    {
      uint256 currentQuoteCollateral = calcRealQuoteCollateral(positionDisQuoteCollateral, positionDisBaseDebt);
      if (currentQuoteCollateral < basePrice.mul(params.positionMinAmount)) revert Errors.LessThanMinimalAmount();
    }

    // quoteOutMinimum is defined by user input limitPriceX96
    uint256 quoteOutMinimum = Math.mulDiv(limitPriceX96, realBaseAmount, FP96.Q96);
    uint256 realQuoteCollateralChangeWithFee = swapExactInput(false, realBaseAmount, quoteOutMinimum, swapCalldata);
    uint256 swapPriceX96 = getSwapPrice(realQuoteCollateralChangeWithFee, realBaseAmount);

    uint256 realSwapFee = Math.mulDiv(params.swapFee, realQuoteCollateralChangeWithFee, WHOLE_ONE);
    uint256 realQuoteCollateralChange = realQuoteCollateralChangeWithFee.sub(realSwapFee);

    if (newPoolQuoteBalance(realQuoteCollateralChange) > params.quoteLimit) revert Errors.ExceedsLimit();

    uint256 discountedBaseDebtChange = baseDebtCoeff.recipMul(realBaseAmount);
    position.discountedBaseAmount = positionDisBaseDebt.add(discountedBaseDebtChange);
    discountedBaseDebt = discountedBaseDebt.add(discountedBaseDebtChange);

    uint256 discountedQuoteChange = quoteCollateralCoeff.recipMul(
      realQuoteCollateralChange.add(quoteDelevCoeff.mul(discountedBaseDebtChange))
    );
    position.discountedQuoteAmount = positionDisQuoteCollateral.add(discountedQuoteChange);
    discountedQuoteCollateral = discountedQuoteCollateral.add(discountedQuoteChange);
    chargeFee(realSwapFee);

    if (position._type == PositionType.Lend) {
      if (position.heapPosition != 0) revert Errors.WrongIndex();
      // init heap with default value 0, it will be updated by 'updateHeap' function later
      shortHeap.insert(positions, MaxBinaryHeapLib.Node({key: 0, account: msg.sender}));
      position._type = PositionType.Short;
    }

    if (positionHasBadLeverage(position, basePrice)) revert Errors.BadLeverage();

    emit Short(msg.sender, realBaseAmount, swapPriceX96, discountedQuoteChange, discountedBaseDebtChange);
  }

  /// @notice Long with leverage
  /// @param realBaseAmount Amount of base token
  /// @param basePrice current oracle base price, got by getBasePrice() method
  /// @param position msg.sender position
  function long(
    uint256 realBaseAmount,
    uint256 limitPriceX96,
    FP96.FixedPoint memory basePrice,
    Position storage position,
    uint256 swapCalldata
  ) private {
    if (basePrice.mul(newPoolBaseBalance(realBaseAmount)) > params.quoteLimit) revert Errors.ExceedsLimit();

    // this function guaranties the position is gonna be either Long or Lend with 0 quote balance
    sellQuoteForBase(position, limitPriceX96, swapCalldata);

    uint256 positionDisQuoteDebt = position.discountedQuoteAmount;
    uint256 positionDisBaseCollateral = position.discountedBaseAmount;

    {
      uint256 currentBaseCollateral = calcRealBaseCollateral(positionDisBaseCollateral, positionDisQuoteDebt);
      if (currentBaseCollateral < params.positionMinAmount) revert Errors.LessThanMinimalAmount();
    }

    // realQuoteInMaximum is defined by user input limitPriceX96
    uint256 realQuoteInMaximum = Math.mulDiv(limitPriceX96, realBaseAmount, FP96.Q96);
    uint256 realQuoteAmount = swapExactOutput(true, realQuoteInMaximum, realBaseAmount, swapCalldata);
    uint256 swapPriceX96 = getSwapPrice(realQuoteAmount, realBaseAmount);

    uint256 realSwapFee = Math.mulDiv(params.swapFee, realQuoteAmount, WHOLE_ONE);
    chargeFee(realSwapFee);

    uint256 discountedQuoteDebtChange = quoteDebtCoeff.recipMul(realQuoteAmount.add(realSwapFee));
    position.discountedQuoteAmount = positionDisQuoteDebt.add(discountedQuoteDebtChange);
    discountedQuoteDebt = discountedQuoteDebt.add(discountedQuoteDebtChange);

    uint256 discountedBaseCollateralChange = baseCollateralCoeff.recipMul(
      realBaseAmount.add(baseDelevCoeff.mul(discountedQuoteDebtChange))
    );
    position.discountedBaseAmount = positionDisBaseCollateral.add(discountedBaseCollateralChange);
    discountedBaseCollateral = discountedBaseCollateral.add(discountedBaseCollateralChange);

    if (position._type == PositionType.Lend) {
      if (position.heapPosition != 0) revert Errors.WrongIndex();
      // init heap with default value 0, it will be updated by 'updateHeap' function later
      longHeap.insert(positions, MaxBinaryHeapLib.Node({key: 0, account: msg.sender}));
      position._type = PositionType.Long;
    }

    if (positionHasBadLeverage(position, basePrice)) revert Errors.BadLeverage();

    emit Long(msg.sender, realBaseAmount, swapPriceX96, discountedQuoteDebtChange, discountedBaseCollateralChange);
  }

  /// @notice sells all the base tokens from lend position for quote ones
  /// @dev no liquidity limit check since this function goes prior to 'short' call and it fail there anyway
  /// @dev you may consider adding that check here if this method is used in any other way
  function sellBaseForQuote(Position storage position, uint256 limitPriceX96, uint256 swapCalldata) private {
    PositionType _type = position._type;
    if (_type == PositionType.Uninitialized) revert Errors.UninitializedPosition();
    if (_type == PositionType.Short) return;

    bool isLong = _type == PositionType.Long;

    uint256 posDiscountedBaseColl = position.discountedBaseAmount;
    uint256 posDiscountedQuoteDebt = isLong ? position.discountedQuoteAmount : 0;
    uint256 baseAmountIn = calcRealBaseCollateral(posDiscountedBaseColl, posDiscountedQuoteDebt);
    if (baseAmountIn == 0) return;

    uint256 quoteAmountOut = swapExactInput(
      false,
      baseAmountIn,
      Math.mulDiv(limitPriceX96, baseAmountIn, FP96.Q96),
      swapCalldata
    );
    uint256 fee = Math.mulDiv(params.swapFee, quoteAmountOut, WHOLE_ONE);
    chargeFee(fee);

    uint256 quoteOutSubFee = quoteAmountOut.sub(fee);
    uint256 realQuoteDebt = quoteDebtCoeff.mul(posDiscountedQuoteDebt);
    uint256 discountedQuoteCollateralDelta = quoteCollateralCoeff.recipMul(quoteOutSubFee.sub(realQuoteDebt));

    discountedBaseCollateral -= posDiscountedBaseColl;
    position.discountedBaseAmount = 0;
    discountedQuoteCollateral += discountedQuoteCollateralDelta;
    if (isLong) {
      discountedQuoteDebt -= posDiscountedQuoteDebt;
      position.discountedQuoteAmount = discountedQuoteCollateralDelta;

      position._type = PositionType.Lend;
      uint32 heapIndex = position.heapPosition - 1;
      longHeap.remove(positions, heapIndex);
      emit QuoteDebtRepaid(msg.sender, realQuoteDebt, posDiscountedQuoteDebt);
    } else {
      position.discountedQuoteAmount += discountedQuoteCollateralDelta;
    }

    emit SellBaseForQuote(
      msg.sender,
      baseAmountIn,
      quoteOutSubFee,
      posDiscountedBaseColl,
      discountedQuoteCollateralDelta
    );
  }

  /// @notice sells all the quote tokens from lend position for base ones
  /// @dev no liquidity limit check since this function goes prior to 'long' call and it fail there anyway
  /// @dev you may consider adding that check here if this method is used in any other way
  function sellQuoteForBase(Position storage position, uint256 limitPriceX96, uint256 swapCalldata) private {
    PositionType _type = position._type;
    if (_type == PositionType.Uninitialized) revert Errors.UninitializedPosition();
    if (_type == PositionType.Long) return;

    bool isShort = _type == PositionType.Short;

    uint256 posDiscountedQuoteColl = position.discountedQuoteAmount;
    uint256 posDiscountedBaseDebt = isShort ? position.discountedBaseAmount : 0;
    uint256 quoteAmountIn = calcRealQuoteCollateral(posDiscountedQuoteColl, posDiscountedBaseDebt);
    if (quoteAmountIn == 0) return;

    uint256 fee = Math.mulDiv(params.swapFee, quoteAmountIn, WHOLE_ONE);
    uint256 quoteInSubFee = quoteAmountIn.sub(fee);

    uint256 baseAmountOut = swapExactInput(
      true,
      quoteInSubFee,
      Math.mulDiv(FP96.Q96, quoteInSubFee, limitPriceX96),
      swapCalldata
    );
    chargeFee(fee);

    uint256 realBaseDebt = baseDebtCoeff.mul(posDiscountedBaseDebt);
    uint256 discountedBaseCollateralDelta = baseCollateralCoeff.recipMul(baseAmountOut.sub(realBaseDebt));

    discountedQuoteCollateral -= posDiscountedQuoteColl;
    position.discountedQuoteAmount = 0;
    discountedBaseCollateral += discountedBaseCollateralDelta;
    if (isShort) {
      discountedBaseDebt -= posDiscountedBaseDebt;
      position.discountedBaseAmount = discountedBaseCollateralDelta;

      position._type = PositionType.Lend;
      uint32 heapIndex = position.heapPosition - 1;
      shortHeap.remove(positions, heapIndex);
      emit BaseDebtRepaid(msg.sender, realBaseDebt, posDiscountedBaseDebt);
    } else {
      position.discountedBaseAmount += discountedBaseCollateralDelta;
    }
    emit SellQuoteForBase(
      msg.sender,
      quoteInSubFee,
      baseAmountOut,
      posDiscountedQuoteColl,
      discountedBaseCollateralDelta
    );
  }

  /// @dev Update collateral and debt coeffs in system
  function accrueInterest() private returns (bool) {
    uint256 secondsPassed = getTimestamp() - lastReinitTimestampSeconds;
    if (secondsPassed == 0) {
      return false;
    }
    lastReinitTimestampSeconds = getTimestamp();

    FP96.FixedPoint memory secondsInYear = FP96.FixedPoint({inner: SECONDS_IN_YEAR_X96});
    FP96.FixedPoint memory interestRate = FP96.fromRatio(params.interestRate, WHOLE_ONE);
    FP96.FixedPoint memory onePlusFee = FP96.fromRatio(params.fee, WHOLE_ONE).div(secondsInYear).add(FP96.one());

    // FEE(dt) = (1 + fee)^dt
    FP96.FixedPoint memory feeDt = FP96.powTaylor(onePlusFee, secondsPassed);

    uint256 discountedBaseFee;
    uint256 discountedQuoteFee;

    if (discountedBaseCollateral != 0) {
      FP96.FixedPoint memory baseDebtCoeffPrev = baseDebtCoeff;
      uint256 realBaseDebtPrev = baseDebtCoeffPrev.mul(discountedBaseDebt);
      FP96.FixedPoint memory onePlusIR = interestRate
        .mul(FP96.FixedPoint({inner: systemLeverage.shortX96}))
        .div(secondsInYear)
        .add(FP96.one());

      // AR(dt) =  (1+ ir)^dt
      FP96.FixedPoint memory accruedRateDt = FP96.powTaylor(onePlusIR, secondsPassed);
      baseDebtCoeff = baseDebtCoeffPrev.mul(accruedRateDt).mul(feeDt);
      FP96.FixedPoint memory factor = FP96.one().add(
        FP96.fromRatio(
          accruedRateDt.sub(FP96.one()).mul(realBaseDebtPrev),
          calcRealBaseCollateral(discountedBaseCollateral, discountedQuoteDebt)
        )
      );
      updateBaseCollateralCoeffs(factor);
      discountedBaseFee = baseCollateralCoeff.recipMul(accruedRateDt.mul(feeDt.sub(FP96.one())).mul(realBaseDebtPrev));
    }

    if (discountedQuoteCollateral != 0) {
      FP96.FixedPoint memory quoteDebtCoeffPrev = quoteDebtCoeff;
      uint256 realQuoteDebtPrev = quoteDebtCoeffPrev.mul(discountedQuoteDebt);
      FP96.FixedPoint memory onePlusIR = interestRate
        .mul(FP96.FixedPoint({inner: systemLeverage.longX96}))
        .div(secondsInYear)
        .add(FP96.one());

      // AR(dt) =  (1+ ir)^dt
      FP96.FixedPoint memory accruedRateDt = FP96.powTaylor(onePlusIR, secondsPassed);
      quoteDebtCoeff = quoteDebtCoeffPrev.mul(accruedRateDt).mul(feeDt);
      FP96.FixedPoint memory factor = FP96.one().add(
        FP96.fromRatio(
          accruedRateDt.sub(FP96.one()).mul(realQuoteDebtPrev),
          calcRealQuoteCollateral(discountedQuoteCollateral, discountedBaseDebt)
        )
      );
      updateQuoteCollateralCoeffs(factor);
      discountedQuoteFee = quoteCollateralCoeff.recipMul(
        accruedRateDt.mul(feeDt.sub(FP96.one())).mul(realQuoteDebtPrev)
      );
    }

    // keep debt fee in technical position
    if (discountedBaseFee != 0 || discountedQuoteFee != 0) {
      Position storage techPosition = getTechPosition();
      techPosition.discountedBaseAmount = techPosition.discountedBaseAmount.add(discountedBaseFee);
      techPosition.discountedQuoteAmount = techPosition.discountedQuoteAmount.add(discountedQuoteFee);

      discountedBaseCollateral = discountedBaseCollateral.add(discountedBaseFee);
      discountedQuoteCollateral = discountedQuoteCollateral.add(discountedQuoteFee);
    }

    emit Reinit(lastReinitTimestampSeconds);

    return true;
  }

  /// @dev Accrue interest and try to reinit riskiest accounts (accounts on top of both heaps)
  function reinit() private returns (bool callerMarginCalled, FP96.FixedPoint memory basePrice) {
    basePrice = getBasePrice();
    if (!accrueInterest()) {
      return (callerMarginCalled, basePrice); // (false, basePrice)
    }

    (bool success, MaxBinaryHeapLib.Node memory root) = shortHeap.getNodeByIndex(0);
    if (success) {
      bool marginCallHappened = reinitAccount(root.account, basePrice);
      callerMarginCalled = marginCallHappened && root.account == msg.sender;
    }

    (success, root) = longHeap.getNodeByIndex(0);
    if (success) {
      bool marginCallHappened = reinitAccount(root.account, basePrice);
      callerMarginCalled = callerMarginCalled || (marginCallHappened && root.account == msg.sender); // since caller can be in short or long position
    }
  }

  function calcRealBaseCollateral(uint256 disBaseCollateral, uint256 disQuoteDebt) private view returns (uint256) {
    return baseCollateralCoeff.mul(disBaseCollateral).sub(baseDelevCoeff.mul(disQuoteDebt));
  }

  function calcRealQuoteCollateral(uint256 disQuoteCollateral, uint256 disBaseDebt) private view returns (uint256) {
    return quoteCollateralCoeff.mul(disQuoteCollateral).sub(quoteDelevCoeff.mul(disBaseDebt));
  }

  function newPoolBaseBalance(uint256 extraRealBaseCollateral) private view returns (uint256) {
    return
      calcRealBaseCollateral(discountedBaseCollateral, discountedQuoteDebt).add(extraRealBaseCollateral).sub(
        baseDebtCoeff.mul(discountedBaseDebt, Math.Rounding.Up)
      );
  }

  function newPoolQuoteBalance(uint256 extraRealQuoteCollateral) private view returns (uint256) {
    return
      calcRealQuoteCollateral(discountedQuoteCollateral, discountedBaseDebt).add(extraRealQuoteCollateral).sub(
        quoteDebtCoeff.mul(discountedQuoteDebt, Math.Rounding.Up)
      );
  }

  /// @dev Recalculates and saves user leverage and enact marginal if needed
  function reinitAccount(address user, FP96.FixedPoint memory basePrice) private returns (bool marginCallHappened) {
    Position storage position = positions[user];

    marginCallHappened = positionHasBadLeverage(position, basePrice);
    if (marginCallHappened) {
      liquidate(user, position, basePrice);
    }
  }

  function positionHasBadLeverage(
    Position storage position,
    FP96.FixedPoint memory basePrice
  ) private view returns (bool) {
    uint256 realTotalCollateral;
    uint256 realTotalDebt;
    if (position._type == PositionType.Short) {
      realTotalCollateral = calcRealQuoteCollateral(position.discountedQuoteAmount, position.discountedBaseAmount);
      realTotalDebt = baseDebtCoeff.mul(basePrice).mul(position.discountedBaseAmount);
    } else if (position._type == PositionType.Long) {
      realTotalCollateral = basePrice.mul(
        calcRealBaseCollateral(position.discountedBaseAmount, position.discountedQuoteAmount)
      );
      realTotalDebt = quoteDebtCoeff.mul(position.discountedQuoteAmount);
    } else {
      return false;
    }

    uint256 maxLeverageX96 = uint256(params.maxLeverage) << FP96.RESOLUTION;
    uint256 leverageX96 = calcLeverage(realTotalCollateral, realTotalDebt);
    return leverageX96 > maxLeverageX96;
  }

  function updateBaseCollateralCoeffs(FP96.FixedPoint memory factor) private {
    baseCollateralCoeff = baseCollateralCoeff.mul(factor);
    baseDelevCoeff = baseDelevCoeff.mul(factor);
  }

  function updateQuoteCollateralCoeffs(FP96.FixedPoint memory factor) private {
    quoteCollateralCoeff = quoteCollateralCoeff.mul(factor);
    quoteDelevCoeff = quoteDelevCoeff.mul(factor);
  }

  function updateHeap(Position storage position) private {
    if (position._type == PositionType.Long) {
      uint96 sortKey = calcSortKey(initialPrice.mul(position.discountedBaseAmount), position.discountedQuoteAmount);
      uint32 heapIndex = position.heapPosition - 1;
      longHeap.update(positions, heapIndex, sortKey);
    } else if (position._type == PositionType.Short) {
      uint96 sortKey = calcSortKey(position.discountedQuoteAmount, initialPrice.mul(position.discountedBaseAmount));
      uint32 heapIndex = position.heapPosition - 1;
      shortHeap.update(positions, heapIndex, sortKey);
    }
  }

  /// @notice Liquidate bad position and receive position collateral and debt
  /// @param badPositionAddress address of position to liquidate
  /// @param quoteAmount amount of quote token to be deposited
  /// @param baseAmount amount of base token to be deposited
  function receivePosition(address badPositionAddress, uint256 quoteAmount, uint256 baseAmount) private {
    if (mode != Mode.Regular) revert Errors.EmergencyMode();

    Position storage position = positions[msg.sender];
    if (position._type != PositionType.Uninitialized) revert Errors.PositionInitialized();

    accrueInterest();
    Position storage badPosition = positions[badPositionAddress];

    FP96.FixedPoint memory basePrice = getBasePrice();
    if (!positionHasBadLeverage(badPosition, basePrice)) revert Errors.NotLiquidatable();

    uint32 heapIndex = badPosition.heapPosition - 1;

    // previous require guarantees that position is either long or short
    if (badPosition._type == PositionType.Short) {
      uint256 discountedQuoteCollateralDelta = quoteCollateralCoeff.recipMul(quoteAmount);
      discountedQuoteCollateral = discountedQuoteCollateral.add(discountedQuoteCollateralDelta);
      position.discountedQuoteAmount = badPosition.discountedQuoteAmount.add(discountedQuoteCollateralDelta);

      uint256 badPositionBaseDebt = baseDebtCoeff.mul(badPosition.discountedBaseAmount);
      uint256 discountedBaseDebtDelta;
      if (baseAmount >= badPositionBaseDebt) {
        discountedBaseDebtDelta = badPosition.discountedBaseAmount;

        uint256 discountedBaseCollateralDelta = baseCollateralCoeff.recipMul(baseAmount.sub(badPositionBaseDebt));
        position.discountedBaseAmount = discountedBaseCollateralDelta;
        discountedBaseCollateral = discountedBaseCollateral.add(discountedBaseCollateralDelta);

        position._type = PositionType.Lend;

        shortHeap.remove(positions, heapIndex);
      } else {
        position._type = PositionType.Short;
        position.heapPosition = heapIndex + 1;
        discountedBaseDebtDelta = baseDebtCoeff.recipMul(baseAmount);
        position.discountedBaseAmount = badPosition.discountedBaseAmount.sub(discountedBaseDebtDelta);

        shortHeap.updateAccount(heapIndex, msg.sender);
      }

      discountedBaseDebt = discountedBaseDebt.sub(discountedBaseDebtDelta);
      discountedQuoteCollateralDelta = quoteCollateralCoeff.recipMul(quoteDelevCoeff.mul(discountedBaseDebtDelta));
      discountedQuoteCollateral -= discountedQuoteCollateralDelta;
      position.discountedQuoteAmount -= discountedQuoteCollateralDelta;
    } else {
      uint256 discountedBaseCollateralDelta = baseCollateralCoeff.recipMul(baseAmount);
      discountedBaseCollateral = discountedBaseCollateral.add(discountedBaseCollateralDelta);
      position.discountedBaseAmount = badPosition.discountedBaseAmount.add(discountedBaseCollateralDelta);

      uint256 badPositionQuoteDebt = quoteDebtCoeff.mul(badPosition.discountedQuoteAmount);
      uint256 discountedQuoteDebtDelta;
      if (quoteAmount >= badPositionQuoteDebt) {
        discountedQuoteDebtDelta = badPosition.discountedQuoteAmount;

        uint256 discountedQuoteCollateralDelta = quoteCollateralCoeff.recipMul(quoteAmount.sub(badPositionQuoteDebt));
        position.discountedQuoteAmount = discountedQuoteCollateralDelta;
        discountedQuoteCollateral = discountedQuoteCollateral.add(discountedQuoteCollateralDelta);

        position._type = PositionType.Lend;

        longHeap.remove(positions, heapIndex);
      } else {
        position._type = PositionType.Long;
        position.heapPosition = heapIndex + 1;
        discountedQuoteDebtDelta = quoteDebtCoeff.recipMul(quoteAmount);
        position.discountedQuoteAmount = badPosition.discountedQuoteAmount.sub(discountedQuoteDebtDelta);

        longHeap.updateAccount(heapIndex, msg.sender);
      }

      discountedQuoteDebt = discountedQuoteDebt.sub(discountedQuoteDebtDelta);
      discountedBaseCollateralDelta = baseCollateralCoeff.recipMul(baseDelevCoeff.mul(discountedQuoteDebtDelta));
      discountedBaseCollateral -= discountedBaseCollateralDelta;
      position.discountedBaseAmount -= discountedBaseCollateralDelta;
    }

    updateHeap(position);

    updateSystemLeverages(basePrice);

    delete positions[badPositionAddress];

    if (positionHasBadLeverage(position, basePrice)) revert Errors.BadLeverage();
    wrapAndTransferFrom(baseToken, msg.sender, baseAmount);
    wrapAndTransferFrom(quoteToken, msg.sender, quoteAmount);

    emit ReceivePosition(
      msg.sender,
      badPositionAddress,
      position._type,
      position.discountedQuoteAmount,
      position.discountedBaseAmount
    );
  }

  /// @inheritdoc IMarginlyPoolOwnerActions
  function shutDown(uint256 swapCalldata) external onlyFactoryOwner lock {
    if (mode != Mode.Regular) revert Errors.EmergencyMode();
    accrueInterest();

    syncBaseBalance();
    syncQuoteBalance();

    FP96.FixedPoint memory basePrice = getBasePrice();

    /* We use Rounding.Up in baseDebt/quoteDebt calculation 
       to avoid case when "surplus = quoteCollateral - quoteDebt"
       a bit more than IERC20(quoteToken).balanceOf(address(this))
     */

    uint256 baseDebt = baseDebtCoeff.mul(discountedBaseDebt, Math.Rounding.Up);
    uint256 quoteCollateral = calcRealQuoteCollateral(discountedQuoteCollateral, discountedBaseDebt);

    uint256 quoteDebt = quoteDebtCoeff.mul(discountedQuoteDebt, Math.Rounding.Up);
    uint256 baseCollateral = calcRealBaseCollateral(discountedBaseCollateral, discountedQuoteDebt);

    if (basePrice.mul(baseDebt) > quoteCollateral) {
      // removing all non-emergency position with bad leverages (negative net positions included)
      (bool success, MaxBinaryHeapLib.Node memory root) = longHeap.getNodeByIndex(0);
      if (success) {
        if (reinitAccount(root.account, basePrice)) {
          return;
        }
      }

      setEmergencyMode(
        Mode.ShortEmergency,
        basePrice,
        baseCollateral,
        baseDebt,
        quoteCollateral,
        quoteDebt,
        swapCalldata
      );
      return;
    }

    if (quoteDebt > basePrice.mul(baseCollateral)) {
      // removing all non-emergency position with bad leverages (negative net positions included)
      (bool success, MaxBinaryHeapLib.Node memory root) = shortHeap.getNodeByIndex(0);
      if (success) {
        if (reinitAccount(root.account, basePrice)) {
          return;
        }
      }

      setEmergencyMode(
        Mode.LongEmergency,
        basePrice,
        quoteCollateral,
        quoteDebt,
        baseCollateral,
        baseDebt,
        swapCalldata
      );
      return;
    }

    revert Errors.NotEmergency();
  }

  ///@dev Set emergency mode and calc emergencyWithdrawCoeff
  function setEmergencyMode(
    Mode _mode,
    FP96.FixedPoint memory shutDownPrice,
    uint256 collateral,
    uint256 debt,
    uint256 emergencyCollateral,
    uint256 emergencyDebt,
    uint256 swapCalldata
  ) private {
    mode = _mode;
    initialPrice = shutDownPrice;

    uint256 balance = collateral >= debt ? collateral.sub(debt) : 0;

    if (emergencyCollateral > emergencyDebt) {
      uint256 surplus = emergencyCollateral.sub(emergencyDebt);

      uint256 collateralSurplus = swapExactInput(_mode == Mode.ShortEmergency, surplus, 0, swapCalldata);

      balance = balance.add(collateralSurplus);
    }

    if (mode == Mode.ShortEmergency) {
      // coeff = price * baseBalance / (price * baseCollateral - quoteDebt)
      emergencyWithdrawCoeff = FP96.fromRatio(
        shutDownPrice.mul(balance),
        shutDownPrice.mul(collateral).sub(emergencyDebt)
      );
    } else {
      // coeff = quoteBalance / (quoteCollateral - price * baseDebt)
      emergencyWithdrawCoeff = FP96.fromRatio(balance, collateral.sub(shutDownPrice.mul(emergencyDebt)));
    }

    emit Emergency(_mode);
  }

  /// @notice Withdraw position collateral in emergency mode
  /// @param unwrapWETH flag to unwrap WETH to ETH
  function emergencyWithdraw(bool unwrapWETH) private {
    if (mode == Mode.Regular) revert Errors.NotEmergency();

    Position memory position = positions[msg.sender];
    if (position._type == PositionType.Uninitialized) revert Errors.UninitializedPosition();

    address token;
    uint256 transferAmount;

    if (mode == Mode.ShortEmergency) {
      if (position._type == PositionType.Short) revert Errors.ShortEmergency();

      // baseNet =  baseColl - quoteDebt / price
      uint256 positionBaseNet = calcRealBaseCollateral(position.discountedBaseAmount, position.discountedQuoteAmount)
        .sub(initialPrice.recipMul(quoteDebtCoeff.mul(position.discountedQuoteAmount)));
      transferAmount = emergencyWithdrawCoeff.mul(positionBaseNet);
      token = baseToken;
    } else {
      if (position._type == PositionType.Long) revert Errors.LongEmergency();

      // quoteNet = quoteColl - baseDebt * price
      uint256 positionQuoteNet = calcRealQuoteCollateral(position.discountedQuoteAmount, position.discountedBaseAmount)
        .sub(baseDebtCoeff.mul(initialPrice).mul(position.discountedBaseAmount));
      transferAmount = emergencyWithdrawCoeff.mul(positionQuoteNet);
      token = quoteToken;
    }

    delete positions[msg.sender];
    unwrapAndTransfer(unwrapWETH, token, msg.sender, transferAmount);

    emit EmergencyWithdraw(msg.sender, token, transferAmount);
  }

  function updateSystemLeverageLong(FP96.FixedPoint memory basePrice) private {
    if (discountedBaseCollateral == 0) {
      systemLeverage.longX96 = uint128(FP96.Q96);
      return;
    }

    uint256 realBaseCollateral = basePrice.mul(calcRealBaseCollateral(discountedBaseCollateral, discountedQuoteDebt));
    uint256 realQuoteDebt = quoteDebtCoeff.mul(discountedQuoteDebt);
    uint128 leverageX96 = uint128(Math.mulDiv(FP96.Q96, realBaseCollateral, realBaseCollateral.sub(realQuoteDebt)));
    uint128 maxLeverageX96 = uint128(params.maxLeverage) << FP96.RESOLUTION;
    systemLeverage.longX96 = leverageX96 < maxLeverageX96 ? leverageX96 : maxLeverageX96;
  }

  function updateSystemLeverageShort(FP96.FixedPoint memory basePrice) private {
    if (discountedQuoteCollateral == 0) {
      systemLeverage.shortX96 = uint128(FP96.Q96);
      return;
    }

    uint256 realQuoteCollateral = calcRealQuoteCollateral(discountedQuoteCollateral, discountedBaseDebt);
    uint256 realBaseDebt = baseDebtCoeff.mul(basePrice).mul(discountedBaseDebt);
    uint128 leverageX96 = uint128(Math.mulDiv(FP96.Q96, realQuoteCollateral, realQuoteCollateral.sub(realBaseDebt)));
    uint128 maxLeverageX96 = uint128(params.maxLeverage) << FP96.RESOLUTION;
    systemLeverage.shortX96 = leverageX96 < maxLeverageX96 ? leverageX96 : maxLeverageX96;
  }

  function updateSystemLeverages(FP96.FixedPoint memory basePrice) private {
    updateSystemLeverageLong(basePrice);
    updateSystemLeverageShort(basePrice);
  }

  /// @dev Wraps ETH into WETH if need and makes transfer from `payer`
  function wrapAndTransferFrom(address token, address payer, uint256 value) private {
    if (msg.value >= value) {
      if (token == getWETH9Address()) {
        IWETH9(token).deposit{value: value}();
        return;
      }
    }
    TransferHelper.safeTransferFrom(token, payer, address(this), value);
  }

  /// @dev Unwraps WETH to ETH and makes transfer to `recipient`
  function unwrapAndTransfer(bool unwrapWETH, address token, address recipient, uint256 value) private {
    if (unwrapWETH) {
      if (token == getWETH9Address()) {
        IWETH9(token).withdraw(value);
        TransferHelper.safeTransferETH(recipient, value);
        return;
      }
    }
    TransferHelper.safeTransfer(token, recipient, value);
  }

  /// @inheritdoc IMarginlyPoolOwnerActions
  function sweepETH() external override onlyFactoryOwner {
    if (address(this).balance > 0) {
      TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }
  }

  /// @dev Changes tech position base collateral so total calculated base balance to be equal to actual
  function syncBaseBalance() private {
    uint256 baseBalance = getBalance(baseToken);
    uint256 actualBaseCollateral = baseDebtCoeff.mul(discountedBaseDebt).add(baseBalance);
    uint256 baseCollateral = calcRealBaseCollateral(discountedBaseCollateral, discountedQuoteDebt);
    Position storage techPosition = getTechPosition();
    if (actualBaseCollateral > baseCollateral) {
      uint256 discountedBaseDelta = baseCollateralCoeff.recipMul(actualBaseCollateral.sub(baseCollateral));
      techPosition.discountedBaseAmount += discountedBaseDelta;
      discountedBaseCollateral += discountedBaseDelta;
    } else {
      uint256 discountedBaseDelta = baseCollateralCoeff.recipMul(baseCollateral.sub(actualBaseCollateral));
      techPosition.discountedBaseAmount -= discountedBaseDelta;
      discountedBaseCollateral -= discountedBaseDelta;
    }
  }

  /// @dev Changes tech position quote collateral so total calculated quote balance to be equal to actual
  function syncQuoteBalance() private {
    uint256 quoteBalance = getBalance(quoteToken);
    uint256 actualQuoteCollateral = quoteDebtCoeff.mul(discountedQuoteDebt).add(quoteBalance);
    uint256 quoteCollateral = calcRealQuoteCollateral(discountedQuoteCollateral, discountedBaseDebt);
    Position storage techPosition = getTechPosition();
    if (actualQuoteCollateral > quoteCollateral) {
      uint256 discountedQuoteDelta = quoteCollateralCoeff.recipMul(actualQuoteCollateral.sub(quoteCollateral));
      techPosition.discountedQuoteAmount += discountedQuoteDelta;
      discountedQuoteCollateral += discountedQuoteDelta;
    } else {
      uint256 discountedQuoteDelta = quoteCollateralCoeff.recipMul(quoteCollateral.sub(actualQuoteCollateral));
      techPosition.discountedQuoteAmount -= discountedQuoteDelta;
      discountedQuoteCollateral -= discountedQuoteDelta;
    }
  }

  /// @dev Used by keeper service
  function getHeapPosition(
    uint32 index,
    bool _short
  ) external view returns (bool success, MaxBinaryHeapLib.Node memory) {
    if (_short) {
      return shortHeap.getNodeByIndex(index);
    } else {
      return longHeap.getNodeByIndex(index);
    }
  }

  /// @dev Returns Uniswap SwapRouter address
  function getSwapRouter() private view returns (address) {
    return IMarginlyFactory(factory).swapRouter();
  }

  /// @dev Calculate swap price in Q96
  function getSwapPrice(uint256 quoteAmount, uint256 baseAmount) private pure returns (uint256) {
    return Math.mulDiv(quoteAmount, FP96.Q96, baseAmount);
  }

  /// @dev Returns tech position
  function getTechPosition() private view returns (Position storage) {
    return positions[IMarginlyFactory(factory).techPositionOwner()];
  }

  /// @dev Returns WETH9 address
  function getWETH9Address() private view returns (address) {
    return IMarginlyFactory(factory).WETH9();
  }

  /// @dev returns ERC20 token balance of this contract
  function getBalance(address erc20Token) private view returns (uint256) {
    return IERC20(erc20Token).balanceOf(address(this));
  }

  /// @param flag unwrapETH in case of withdraw calls or syncBalance in case of reinit call
  function execute(
    CallType call,
    uint256 amount1,
    int256 amount2,
    uint256 limitPriceX96,
    bool flag,
    address receivePositionAddress,
    uint256 swapCalldata
  ) external payable override lock {
    if (call == CallType.ReceivePosition) {
      if (amount2 < 0) revert Errors.WrongValue();
      receivePosition(receivePositionAddress, amount1, uint256(amount2));
      return;
    } else if (call == CallType.EmergencyWithdraw) {
      emergencyWithdraw(flag);
      return;
    }

    if (mode != Mode.Regular) revert Errors.EmergencyMode();

    (bool callerMarginCalled, FP96.FixedPoint memory basePrice) = reinit();
    if (callerMarginCalled) {
      updateSystemLeverages(basePrice);
      return;
    }

    Position storage position = positions[msg.sender];

    if (positionHasBadLeverage(position, basePrice)) {
      liquidate(msg.sender, position, basePrice);
      updateSystemLeverages(basePrice);
      return;
    }

    if (call == CallType.DepositBase) {
      depositBase(amount1, basePrice, position);
      if (amount2 > 0) {
        long(uint256(amount2), limitPriceX96, basePrice, position, swapCalldata);
      } else if (amount2 < 0) {
        short(uint256(-amount2), limitPriceX96, basePrice, position, swapCalldata);
      }
    } else if (call == CallType.DepositQuote) {
      depositQuote(amount1, position);
      if (amount2 > 0) {
        short(uint256(amount2), limitPriceX96, basePrice, position, swapCalldata);
      } else if (amount2 < 0) {
        long(uint256(-amount2), limitPriceX96, basePrice, position, swapCalldata);
      }
    } else if (call == CallType.WithdrawBase) {
      withdrawBase(amount1, flag, basePrice, position);
    } else if (call == CallType.WithdrawQuote) {
      withdrawQuote(amount1, flag, basePrice, position);
    } else if (call == CallType.Short) {
      short(amount1, limitPriceX96, basePrice, position, swapCalldata);
    } else if (call == CallType.Long) {
      long(amount1, limitPriceX96, basePrice, position, swapCalldata);
    } else if (call == CallType.ClosePosition) {
      closePosition(limitPriceX96, position, swapCalldata);
    } else if (call == CallType.Reinit && flag) {
      // reinit itself has already taken place
      syncBaseBalance();
      syncQuoteBalance();
      emit BalanceSync();
    }

    updateHeap(position);

    updateSystemLeverages(basePrice);
  }

  function getTimestamp() internal view virtual returns (uint256) {
    return block.timestamp;
  }
}