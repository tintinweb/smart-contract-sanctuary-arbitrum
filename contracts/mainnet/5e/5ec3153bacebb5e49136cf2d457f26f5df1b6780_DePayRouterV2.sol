/**
 *Submitted for verification at Arbiscan on 2023-08-14
*/

// Dependency file: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


// Dependency file: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

// pragma solidity ^0.8.0;

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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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


// Dependency file: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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


// Dependency file: contracts/interfaces/IPermit2.sol


// pragma solidity >=0.8.18 <0.9.0;

interface IPermit2 {

  struct PermitDetails {
    address token;
    uint160 amount;
    uint48 expiration;
    uint48 nonce;
  }

  struct PermitSingle {
    PermitDetails details;
    address spender;
    uint256 sigDeadline;
  }

  function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

  function transferFrom(address from, address to, uint160 amount, address token) external;

  function allowance(address user, address token, address spender) external view returns (uint160 amount, uint48 expiration, uint48 nonce);

}


// Dependency file: contracts/interfaces/IDePayRouterV2.sol


// pragma solidity >=0.8.18 <0.9.0;

// import 'contracts/interfaces/IPermit2.sol';

interface IDePayRouterV2 {

  struct Payment {
    uint256 amountIn;
    bool permit2;
    uint256 paymentAmount;
    uint256 feeAmount;
    address tokenInAddress;
    address exchangeAddress;
    address tokenOutAddress;
    address paymentReceiverAddress;
    address feeReceiverAddress;
    uint8 exchangeType;
    uint8 receiverType;
    bytes exchangeCallData;
    bytes receiverCallData;
    uint256 deadline;
  }

  function pay(
    Payment calldata payment
  ) external payable returns(bool);

  function pay(
    IDePayRouterV2.Payment calldata payment,
    IPermit2.PermitSingle memory permitSingle,
    bytes calldata signature
  ) external payable returns(bool);

  event Enabled(
    address indexed exchange
  );

  event Disabled(
    address indexed exchange
  );

  function enable(address exchange, bool enabled) external returns(bool);

  function withdraw(address token, uint amount) external returns(bool);

}


// Dependency file: contracts/interfaces/IDePayForwarderV2.sol


// pragma solidity >=0.8.18 <0.9.0;

// import 'contracts/interfaces/IDePayRouterV2.sol';

interface IDePayForwarderV2 {

  function forward(
    IDePayRouterV2.Payment calldata payment
  ) external payable returns(bool);

  function toggle(bool stop) external returns(bool);

}


// Root file: contracts/DePayRouterV2.sol


pragma solidity >=0.8.18 <0.9.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import 'contracts/interfaces/IPermit2.sol';
// import 'contracts/interfaces/IDePayRouterV2.sol';
// import 'contracts/interfaces/IDePayForwarderV2.sol';

contract DePayRouterV2 is Ownable {

  using SafeERC20 for IERC20;

  // Address representing the NATIVE token (e.g. ETH, BNB, MATIC, etc.)
  address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  // Address of PERMIT2
  address public immutable PERMIT2;

  // Address of the payment FORWARDER contract
  address public immutable FORWARDER;

  // List of approved exchanges for conversion
  mapping (address => bool) public exchanges;

  constructor (address _PERMIT2, address _FORWARDER) {
    PERMIT2 = _PERMIT2;
    FORWARDER = _FORWARDER;
  }

  // Accepts NATIVE payments, which is required in order to swap from and to NATIVE, especially unwrapping as part of conversions
  receive() external payable {}

  // Transfer polyfil event for internal transfers
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  // Perform a payment (tokenIn approval has been granted prior), internal
  function _pay(
    IDePayRouterV2.Payment calldata payment
  ) internal returns(bool){
    uint256 balanceInBefore;
    uint256 balanceOutBefore;

    (balanceInBefore, balanceOutBefore) = _validatePreConditions(payment);
    _payIn(payment);
    _performPayment(payment);
    _validatePostConditions(payment, balanceInBefore, balanceOutBefore);

    return true;
  }

  // Perform a payment (tokenIn approval has been granted prior), external
  function pay(
    IDePayRouterV2.Payment calldata payment
  ) external payable returns(bool){
    return _pay(payment);
  }

  // Perform a payment (including permit2 approval), internal
  function _pay(
    IDePayRouterV2.Payment calldata payment,
    IPermit2.PermitSingle memory permitSingle,
    bytes calldata signature
  ) internal returns(bool){
    uint256 balanceInBefore;
    uint256 balanceOutBefore;

    (balanceInBefore, balanceOutBefore) = _validatePreConditions(payment);
    _permit(permitSingle, signature);
    _payIn(payment);
    _performPayment(payment);
    _validatePostConditions(payment, balanceInBefore, balanceOutBefore);

    return true;
  }

  // Perform a payment (including permit2 approval), external
  function pay(
    IDePayRouterV2.Payment calldata payment,
    IPermit2.PermitSingle memory permitSingle,
    bytes calldata signature
  ) external payable returns(bool){
    return _pay(payment, permitSingle, signature);
  }

  function _validatePreConditions(IDePayRouterV2.Payment calldata payment) internal returns(uint256 balanceInBefore, uint256 balanceOutBefore) {
    // Make sure payment deadline has not been passed, yet
    require(payment.deadline > block.timestamp, "DePay: Payment deadline has passed!");

    // Store tokenIn balance prior to payment
    if(payment.tokenInAddress == NATIVE) {
      balanceInBefore = address(this).balance - msg.value;
    } else {
      balanceInBefore = IERC20(payment.tokenInAddress).balanceOf(address(this));
    }

    // Store tokenOut balance prior to payment
    if(payment.tokenOutAddress == NATIVE) {
      balanceOutBefore = address(this).balance - msg.value;
    } else {
      balanceOutBefore = IERC20(payment.tokenOutAddress).balanceOf(address(this));
    }
  }

  // permit2
  function _permit(
    IPermit2.PermitSingle memory permitSingle,
    bytes calldata signature
  ) internal {

    IPermit2(PERMIT2).permit(
      msg.sender, // owner
      permitSingle,
      signature
    );
  }

  // pay in using token approval & transferFrom or requiring native pay in
  function _payIn(
    IDePayRouterV2.Payment calldata payment
  ) internal {
    // Make sure that the sender has paid in the correct token & amount
    if(payment.tokenInAddress == NATIVE) {
      require(msg.value >= payment.amountIn, 'DePay: Insufficient amount paid in!');
    } else if(payment.permit2) {
      IPermit2(PERMIT2).transferFrom(msg.sender, address(this), uint160(payment.amountIn), payment.tokenInAddress);
    } else {
      IERC20(payment.tokenInAddress).safeTransferFrom(msg.sender, address(this), payment.amountIn);
    }
  }

  function _performPayment(IDePayRouterV2.Payment calldata payment) internal {
    // Perform conversion if required
    if(payment.exchangeAddress != address(0)) {
      _convert(payment);
    }

    // Perform payment to paymentReceiver
    _payReceiver(payment);

    // Perform payment to feeReceiver
    if(payment.feeReceiverAddress != address(0)) {
      _payFee(payment);
    }
  }

  function _validatePostConditions(IDePayRouterV2.Payment calldata payment, uint256 balanceInBefore, uint256 balanceOutBefore) internal view {
    // Ensure balances of tokenIn remained
    if(payment.tokenInAddress == NATIVE) {
      require(address(this).balance >= balanceInBefore, 'DePay: Insufficient balanceIn after payment!');
    } else {
      require(IERC20(payment.tokenInAddress).balanceOf(address(this)) >= balanceInBefore, 'DePay: Insufficient balanceIn after payment!');
    }

    // Ensure balances of tokenOut remained
    if(payment.tokenOutAddress == NATIVE) {
      require(address(this).balance >= balanceOutBefore, 'DePay: Insufficient balanceOut after payment!');
    } else {
      require(IERC20(payment.tokenOutAddress).balanceOf(address(this)) >= balanceOutBefore, 'DePay: Insufficient balanceOut after payment!');
    }
  }

  function _convert(IDePayRouterV2.Payment calldata payment) internal {
    require(exchanges[payment.exchangeAddress], 'DePay: Exchange has not been approved!');
    bool success;
    if(payment.tokenInAddress == NATIVE) {
      (success,) = payment.exchangeAddress.call{value: msg.value}(payment.exchangeCallData);
    } else {
      if(payment.exchangeType == 1) { // pull
        IERC20(payment.tokenInAddress).safeApprove(payment.exchangeAddress, payment.amountIn);
      } else if(payment.exchangeType == 2) { // push
        IERC20(payment.tokenInAddress).safeTransfer(payment.exchangeAddress, payment.amountIn);
      }
      (success,) = payment.exchangeAddress.call(payment.exchangeCallData);
    }
    require(success, "DePay: exchange call failed!");
  }

  function _payReceiver(IDePayRouterV2.Payment calldata payment) internal {
    if(payment.receiverType != 0) { // call receiver contract

      {
        bool success;
        if(payment.tokenOutAddress == NATIVE) {
          success = IDePayForwarderV2(FORWARDER).forward{value: payment.paymentAmount}(payment);
          emit Transfer(msg.sender, payment.paymentReceiverAddress, payment.paymentAmount);
        } else {
          IERC20(payment.tokenOutAddress).safeTransfer(FORWARDER, payment.paymentAmount);
          success = IDePayForwarderV2(FORWARDER).forward(payment);
        }
        require(success, 'DePay: Forwarding payment to contract failed!');
      }

    } else { // just send payment to address

      if(payment.tokenOutAddress == NATIVE) {
        (bool success,) = payment.paymentReceiverAddress.call{value: payment.paymentAmount}(new bytes(0));
        require(success, 'DePay: NATIVE payment receiver pay out failed!');
        emit Transfer(msg.sender, payment.paymentReceiverAddress, payment.paymentAmount);
      } else {
        IERC20(payment.tokenOutAddress).safeTransfer(payment.paymentReceiverAddress, payment.paymentAmount);
      }
    }
  }

  function _payFee(IDePayRouterV2.Payment calldata payment) internal {
    if(payment.tokenOutAddress == NATIVE) {
      (bool success,) = payment.feeReceiverAddress.call{value: payment.feeAmount}(new bytes(0));
      require(success, 'DePay: NATIVE fee receiver pay out failed!');
      emit Transfer(msg.sender, payment.feeReceiverAddress, payment.feeAmount);
    } else {
      IERC20(payment.tokenOutAddress).safeTransfer(payment.feeReceiverAddress, payment.feeAmount);
    }
  }

  // Event emitted if new exchange has been enabled
  event Enabled(
    address indexed exchange
  );

  // Event emitted if an exchange has been disabled
  event Disabled(
    address indexed exchange
  );

  // Enable/Disable an exchange
  function enable(address exchange, bool enabled) external onlyOwner returns(bool) {
    exchanges[exchange] = enabled;
    if(enabled) {
      emit Enabled(exchange);
    } else {
      emit Disabled(exchange);
    }
    return true;
  }

  // Allows to withdraw accidentally sent tokens.
  function withdraw(
    address token,
    uint amount
  ) external onlyOwner returns(bool) {
    if(token == NATIVE) {
      (bool success,) = address(msg.sender).call{value: amount}(new bytes(0));
      require(success, 'DePay: withdraw failed!');
    } else {
      IERC20(token).safeTransfer(msg.sender, amount);
    }
    return true;
  }
}