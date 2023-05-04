/**
 *Submitted for verification at Arbiscan on 2023-05-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.19;

abstract contract Adminable {
    address public admin;
    address public candidate;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event AdminCandidateRegistered(address indexed admin, address indexed candidate);

    constructor(address _admin) {
        require(_admin != address(0), "admin is the zero address");
        admin = _admin;
        emit AdminChanged(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return account == admin;
    }

    function registerAdminCandidate(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "new admin is the zero address");
        candidate = _newAdmin;
        emit AdminCandidateRegistered(admin, _newAdmin);
    }

    function confirmAdmin() external {
        require(msg.sender == candidate, "only candidate");
        emit AdminChanged(admin, candidate);
        admin = candidate;
        candidate = address(0);
    }
}


abstract contract OperatorAdminable is Adminable {
    mapping(address => bool) private _operators;

    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);

    modifier onlyAdminOrOperator() {
        require(isAdmin(msg.sender) || isOperator(msg.sender), "OperatorAdminable: caller is not admin or operator");
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators[account];
    }

    function addOperator(address account) external onlyAdmin {
        require(account != address(0), "OperatorAdminable: operator is the zero address");
        require(!_operators[account], "OperatorAdminable: operator already added");
        _operators[account] = true;
        emit OperatorAdded(account);
    }

    function removeOperator(address account) external onlyAdmin {
        require(_operators[account], "OperatorAdminable: operator not found");
        _operators[account] = false;
        emit OperatorRemoved(account);
    }
}


abstract contract Pausable is OperatorAdminable {
    bool public paused;

    event Paused();
    event Resumed();

    constructor(address _admin) Adminable(_admin) {}

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    function pause() external onlyAdmin {
        paused = true;
        emit Paused();
    }

    function resume() external onlyAdmin {
        paused = false;
        emit Resumed();
    }
}


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


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool); //
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); //
    function balanceOf(address account) external view returns (uint256); //
    function mint(address account, uint256 amount) external returns (bool); //
    function approve(address spender, uint256 amount) external returns (bool); //
    function allowance(address owner, address spender) external view returns (uint256); //
}


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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
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


interface IRewardRouter {
    function gmx() external view returns (address);
    function esGmx() external view returns (address);
    function glp() external view returns (address);
    function weth() external view returns (address);
    function bnGmx() external view returns (address);

    function stakedGmxTracker() external view returns (address);
    function bonusGmxTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function stakedGlpTracker() external view returns (address);
    function feeGlpTracker() external view returns (address);
    function gmxVester() external view returns (address);
    function glpVester() external view returns (address);

    function stakeEsGmx(uint256 _amount) external;
    
    function signalTransfer(address _receiver) external;
    function acceptTransfer(address _sender) external;

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);
    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address payable _receiver) external returns (uint256);

    function claim() external;
    function pendingReceivers(address _account) external view returns (address);
}


interface IConverter {
    function gmx() external view returns (address);
    function esGmx() external view returns (address);
    function bnGmx() external view returns (address);
    function rewardRouter() external view returns (IRewardRouter);
    function stakedGmxTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function stakedGlp() external view returns (address);
    function GMXkey() external view returns (address);
    function esGMXkey() external view returns (address);
    function MPkey() external view returns (address);
    function rewards() external view returns (address);
    function treasury() external view returns (address);
    function operator() external view returns (address);
    function transferReceiver() external view returns (address);
    function feeCalculator() external view returns (address);
    function receivers(address _account) external view returns (address);
    function minGmxAmount() external view returns (uint128);
    function qualifiedRatio() external view returns (uint32);
    function isForMpKey(address sender) external view returns (bool);
    function registeredReceivers(uint256 index) external view returns (address);
    function registeredReceiversLength() external view returns (uint256);
    function isValidReceiver(address _receiver) external view returns (bool);
    function convertedAmount(address accountn, address token) external view returns (uint256);
    function feeCalculatorReserved() external view returns (address, uint256);
    function setQualification(uint128 _minGmxAmount, uint32 _qualifiedRatio) external;
    function createTransferReceiver() external;
    function approveMpKeyConversion(address _receiver, bool _approved) external;
    function completeConversion() external;
    function completeConversionToMpKey(address sender) external;
    event ReceiverRegistered(address indexed receiver, uint256 activeAt);
    event ReceiverCreated(address indexed account, address indexed receiver);
    event ConvertCompleted(address indexed account, address indexed receiver, uint256 gmxAmount, uint256 esGmxAmount, uint256 mpAmount);
    event ConvertForMpCompleted(address indexed account, address indexed receiver, uint256 amount);
    event ConvertingFeeCalculatorReserved(address to, uint256 at);

}


interface IReserved {

    struct Reserved {
        address to;
        uint256 at;
    }

}


interface ITransferReceiver is IReserved {
    function initialize(
        address _admin,
        address _config,
        address _converter,
        IRewardRouter _rewardRouter,
        address _stakedGlp,
        address _rewards
    ) external;
    function rewardRouter() external view returns (IRewardRouter);
    function stakedGlpTracker() external view returns (address);
    function weth() external view returns (address);
    function esGmx() external view returns (address);
    function stakedGlp() external view returns (address);
    function converter() external view returns (address);
    function rewards() external view returns (address);
    function transferSender() external view returns (address);
    function transferSenderReserved() external view returns (address to, uint256 at);
    function newTransferReceiverReserved() external view returns (address to, uint256 at);
    function accepted() external view returns (bool);
    function isForMpKey() external view returns (bool);
    function reserveTransferSender(address _transferSender, uint256 _at) external;
    function setTransferSender() external;
    function reserveNewTransferReceiver(address _newTransferReceiver, uint256 _at) external;
    function claimAndUpdateReward(address feeTo) external;
    function signalTransfer(address to) external;
    function acceptTransfer(address sender, bool _isForMpKey) external;
    function version() external view returns (uint256);
    event TransferAccepted(address indexed sender);
    event SignalTransfer(address indexed from, address indexed to);
    event TokenWithdrawn(address token, address to, uint256 balance);
    event TransferSenderReserved(address transferSender, uint256 at);
    event NewTransferReceiverReserved(address indexed to, uint256 at);
}


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


contract ConfigUser {
    address public immutable config;

    constructor(address _config) {
        require(_config != address(0), "ConfigUser: config is the zero address");
        config = _config;
    }
}


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


interface IConfig {
    function MIN_DELAY_TIME() external pure returns (uint256);
    function upgradeDelayTime() external view returns (uint256);
    function setUpgradeDelayTime(uint256 time) external;
    function getUpgradeableAt() external view returns (uint256);
}


interface IRewards {
    function FEE_PERCENTAGE_BASE() external view returns (uint16);
    function FEE_PERCENTAGE_MAX() external view returns (uint16);
    function FEE_TIER_LENGTH_MAX() external view returns (uint128);
    function PRECISION() external view returns (uint128);
    function PERIOD() external view returns (uint256);
    function stakedGmxTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function gmx() external view returns (address);
    function esGmx() external view returns (address);
    function bnGmx() external view returns (address);
    function weth() external view returns (address);
    function GMXkey() external view returns (address);
    function esGMXkey() external view returns (address);
    function MPkey() external view returns (address);
    function staker() external view returns (address);
    function converter() external view returns (address);
    function treasury() external view returns (address);
    function feeCalculator() external view returns (address);
    function rewardPerUnit(address stakingToken, address rewardToken, uint256 periodIndex) external view returns (uint256);
    function lastRewardPerUnit(address account, address stakingToken, address rewardToken, uint256 periodIndex) external view returns (uint256);
    function reward(address account, address stakingToken, address rewardToken) external view returns (uint256);
    function lastDepositBalancesForReceivers(address receiver, address token) external view returns (uint256);
    function cumulatedReward(address stakingToken, address rewardToken) external view returns (uint256);
    function feeTiers(address rewardToken, uint256 index) external view returns (uint256);
    function feePercentages(address rewardToken, uint256 index) external view returns (uint16);
    function feeLength(address rewardToken) external view returns (uint256);
    function lastUpdatedAt(address receiver) external view returns (uint256);
    function currentPeriodIndex() external view returns (uint256);
    function maxPeriodsToUpdateRewards() external view returns (uint256);
    function feeCalculatorReserved() external view returns (address, uint256);
    function setTreasury(address _treasury) external;
    function setConverter(address _converter) external;
    function reserveFeeCalculator(address _feeCalculator, uint256 _at) external;
    function setFeeCalculator() external;
    function setFeeTiersAndPercentages(address _rewardToken, uint256[] memory _feeTiers, uint16[] memory _feePercentages) external;
    function setMaxPeriodsToUpdateRewards(uint256 _maxPeriodsToUpdateRewards) external;
    function claimRewardWithIndices(address account, uint256[] memory periodIndices) external;
    function claimRewardWithCount(address account, uint256 count) external;
    function claimableRewardWithIndices(address account, uint256[] memory periodIndices) external view returns(uint256 esGMXkeyRewardByGMXkey, uint256 esGMXkeyRewardByEsGMXkey, uint256 mpkeyRewardByGMXkey, uint256 mpkeyRewardByEsGMXkey, uint256 wethRewardByGMXkey, uint256 wethRewardByEsGMXkey, uint256 wethRewardByMPkey);
    function claimableRewardWithCount(address account, uint256 count) external view returns (uint256 esGMXkeyRewardByGMXkey, uint256 esGMXkeyRewardByEsGMXkey, uint256 mpkeyRewardByGMXkey, uint256 mpkeyRewardByEsGMXkey, uint256 wethRewardByGMXkey, uint256 wethRewardByEsGMXkey, uint256 wethRewardByMPkey);
    function initTransferReceiver() external;
    function updateAllRewardsForTransferReceiverAndTransferFee(address feeTo) external;
    event RewardClaimed(
        address indexed account,
        uint256 esGMXKeyAmountByGMXkey, uint256 esGMXKeyFeeByGMXkey, uint256 mpKeyAmountByGMXKey, uint256 mpKeyFeeByGMXkey,
        uint256 esGmxKeyAmountByEsGMXkey, uint256 esGmxKeyFeeByEsGMXkey, uint256 mpKeyAmountByEsGMXkey, uint256 mpKeyFeeByEsGMXkey,
        uint256 ethAmountByGMXkey, uint256 ethFeeByGMXkey,
        uint256 ethAmountByEsGMXkey, uint256 ethFeeByEsGMXkey,
        uint256 ethAmountByMPkey, uint256 ethFeeByMPkey);
    event ReceiverInitialized(address indexed receiver, uint256 stakedGmxAmount, uint256 stakedEsGmxAmount, uint256 stakedMpAmount);
    event RewardsCalculated(address indexed receiver, uint256 esGmxKeyAmountToMint, uint256 mpKeyAmountToMint, uint256 wethAmountToTransfer);
    event FeeUpdated(address token, uint256[] newFeeTiers, uint16[] newFeePercentages);
    event StakingFeeCalculatorReserved(address to, uint256 at);
}


interface IRewardTracker {
    function unstake(address _depositToken, uint256 _amount) external;
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function stakedAmounts(address account) external view returns (uint256);
    function depositBalances(address account, address depositToken) external view returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function glp() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
}



interface IStaker {
    // Events
    event Staked(address indexed user, address indexed token, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 amount);

    // State-changing functions
    function stake(address token, uint256 amount) external;
    function unstake(address token, uint256 amount) external;
    function updatePastTotalSharesByPeriod(address token, uint256 count) external;
    function updatePastUserSharesByPeriod(address account, address token, uint256 count) external;

    // Getter functions for public variables
    function totalBalance(address token) external view returns (uint256);
    function userBalance(address user, address token) external view returns (uint256);
    function totalSharesByPeriod(address token, uint256 periodIndex) external view returns (uint256);
    function userSharesByPeriod(address user, address token, uint256 periodIndex) external view returns (uint256);
    function latestTotalShares(address token) external view returns (uint256);
    function latestTotalSharesUpdatedAt(address token) external view returns (uint256);
    function latestUserShares(address user, address token) external view returns (uint256);
    function latestUserSharesUpdatedAt(address user, address token) external view returns (uint256);

    // View functions
    function totalSharesPrevPeriod(address token) external view returns (uint256);

    function GMXkey() external view returns (address);
    function esGMXkey() external view returns (address);
    function MPkey() external view returns (address);

    function PERIOD() external view returns (uint256);

}


interface IStakingFeeCalculator {
    function calculateStakingFee(
        address account,
        uint256 amount,
        address stakingToken,
        address rewardToken
    ) external view returns (uint256);
}


interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function withdrawTo(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}



/**
 * @title Rewards
 * @author Key Finance
 * @notice
 * This contract enables users to request and claim rewards produced by staking GMXkey, esGMXkey, and MPkey.
 * Moreover, it encompasses a range of functions necessary for handling records associated with reward distribution.
 * A significant example is the updateAllRewardsForTransferReceiverAndTransferFee function, invoked from TransferReceiver contract.
 */
contract Rewards is IRewards, IReserved, ConfigUser, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // constants
    uint16 public constant FEE_PERCENTAGE_BASE = 10000;
    uint16 public constant FEE_PERCENTAGE_MAX = 2500;
    uint128 public constant FEE_TIER_LENGTH_MAX = 10;
    uint128 public constant PRECISION = 1e36;
    uint256 public constant PERIOD = 1 weeks;

    // external contracts
    address public immutable stakedGmxTracker;
    address public immutable feeGmxTracker;
    address public immutable gmx;
    address public immutable esGmx;
    address public immutable bnGmx;
    address public immutable weth;

    // key protocol contracts & addresses
    address public immutable GMXkey;
    address public immutable esGMXkey;
    address public immutable MPkey;
    address public immutable staker;
    address public converter;
    address public treasury;
    address public feeCalculator;

    // state variables
    mapping(address => mapping(address => mapping(uint256 => uint256))) public rewardPerUnit;
    mapping(address => mapping(address => mapping(address => mapping(uint256 => uint256)))) public lastRewardPerUnit;
    mapping(address => mapping(address => mapping(address => uint256))) public reward;
    mapping(address => mapping(address => uint256)) public lastDepositBalancesForReceivers;
    mapping(address => mapping(address => uint256)) public cumulatedReward;
    mapping(address => uint256[]) public feeTiers;
    mapping(address => uint16[]) public feePercentages;
    mapping(address => uint256) public lastUpdatedAt;
    uint256 public currentPeriodIndex;
    uint256 public maxPeriodsToUpdateRewards;
    Reserved public feeCalculatorReserved;

    constructor(address _admin, address _config, IRewardRouter _rewardRouter, address _GMXkey, address _esGMXkey, address _MPkey, address _staker, address _treasury, address _feeCalculator) Pausable(_admin) ConfigUser(_config) {
        require(address(_rewardRouter) != address(0), "Rewards: rewardRouter must not be zero address");
        require(_GMXkey != address(0), "Rewards: GMXkey must not be zero address");
        require(_esGMXkey != address(0), "Rewards: esGMXkey must not be zero address");
        require(_MPkey != address(0), "Rewards: MPkey must not be zero address");
        require(_staker != address(0), "Rewards: staker must not be zero address");
        require(_treasury != address(0), "Rewards: treasury must not be zero address");
        require(_feeCalculator != address(0), "Rewards: feeCalculator must not be zero address");
        stakedGmxTracker = _rewardRouter.stakedGmxTracker();
        require(stakedGmxTracker != address(0), "Rewards: stakedGmxTracker must not be zero address");
        feeGmxTracker = _rewardRouter.feeGmxTracker();
        require(feeGmxTracker != address(0), "Rewards: feeGmxTracker must not be zero address");
        gmx = _rewardRouter.gmx();
        require(gmx != address(0), "Rewards: gmx must not be zero address");
        esGmx = _rewardRouter.esGmx();
        require(esGmx != address(0), "Rewards: esGmx must not be zero address");
        bnGmx = _rewardRouter.bnGmx();
        require(bnGmx != address(0), "Rewards: bnGmx must not be zero address");
        GMXkey = _GMXkey;
        esGMXkey = _esGMXkey;
        MPkey = _MPkey;
        weth = _rewardRouter.weth();
        require(weth != address(0), "Rewards: weth must not be zero address");
        staker = _staker;
        treasury = _treasury;
        feeCalculator = _feeCalculator;
        maxPeriodsToUpdateRewards = 4;
        _initializePeriod();
    }

    // - config functions - //

    // Sets treasury address
    function setTreasury(address _treasury) external onlyAdmin {
        require(_treasury != address(0), "Rewards: _treasury is the zero address");
        treasury = _treasury;
    }

    // Sets converter address
    function setConverter(address _converter) external onlyAdmin {
        require(_converter != address(0), "Rewards: _converter is the zero address");
        converter = _converter;
    }

    /**
     * @notice Reserves to set feeCalculator contract.
     * @param _feeCalculator contract address
     * @param _at _feeCalculator can be set after this time
     */
    function reserveFeeCalculator(address _feeCalculator, uint256 _at) external onlyAdmin {
        require(_feeCalculator != address(0), "Rewards: feeCalculator is the zero address");
        require(_at >= IConfig(config).getUpgradeableAt(), "Rewards: at should be later");
        feeCalculatorReserved = Reserved(_feeCalculator, _at);
        emit StakingFeeCalculatorReserved(_feeCalculator, _at);
    }
    
    // Sets reserved FeeCalculator contract.
    function setFeeCalculator() external onlyAdmin {
        require(feeCalculatorReserved.at != 0 && feeCalculatorReserved.at <= block.timestamp, "Rewards: feeCalculator is not yet available");
        feeCalculator = feeCalculatorReserved.to;
    }

    /**
     * @notice Sets the fee tiers and fee amount to be paid to the account calling the reward settlement function for a specific receiver.
     * @param _rewardToken The token type for which the fee will be applied. esGMXkey, MPkey, and weth are all possible.
     * @param _feeTiers Sets the tiers of fee
     * @param _feePercentages Sets the amount of fee to be charged. It is set in 0.01% increments. 10000 = 100%
     */
    function setFeeTiersAndPercentages(address _rewardToken, uint256[] memory _feeTiers, uint16[] memory _feePercentages) external onlyAdmin {
        require(_feeTiers.length == _feePercentages.length, "Rewards: Fee tiers and percentages arrays must have the same length");
        require(_feeTiers.length <= FEE_TIER_LENGTH_MAX, "Rewards: The length of Fee tiers cannot exceed FEE_TIER_LENGTH_MAX");
        require(_rewardToken == esGMXkey || _rewardToken == MPkey || _rewardToken == weth, "Rewards: rewardToken must be esGMXkey, MPkey, or weth");

        // Check if the _feeTiers array is sorted
        for (uint256 i = 1; i < _feeTiers.length; i++) {
            require(_feeTiers[i] < _feeTiers[i - 1], "Rewards: _feeTiers must be sorted in descending order");
        }

        for (uint256 i = 0; i < _feePercentages.length; i++) {
            require(_feePercentages[i] <= FEE_PERCENTAGE_MAX, "Rewards: ratio must be less than or equal to 2500");
        }

        feeTiers[_rewardToken] = _feeTiers;
        feePercentages[_rewardToken] = _feePercentages;
        emit FeeUpdated(_rewardToken, _feeTiers, _feePercentages);
    }

    // Sets max periods to update rewards
    function setMaxPeriodsToUpdateRewards(uint256 maxPeriods) external onlyAdmin {
        require(maxPeriods >= 1, "Rewards: maxPeriods must be greater than or equal to 1");
        maxPeriodsToUpdateRewards = maxPeriods;
    }

    // - external state-changing functions - //

    /**
     * @notice Allows any user to claim rewards for 'account'.
     * Claim for specified periods.
     * @param account The account to claim rewards for.
     * @param periodIndices The periods to claim rewards for.
     */
    function claimRewardWithIndices(address account, uint256[] memory periodIndices) external nonReentrant whenNotPaused {
        _updateAllPastShareByPeriods(account);

        for (uint256 i = 0; i < periodIndices.length; i++) {
            _updateAccountReward(account, periodIndices[i]);
        }
        _claimReward(account);
    }

    /**
     * @notice Allows any user to claim rewards for 'account'.
     * Claim for the recent periods.
     * @param account The account to claim rewards for.
     * @param count The number of periods to claim rewards for.
     */
    function claimRewardWithCount(address account, uint256 count) external nonReentrant whenNotPaused {
        if (count > currentPeriodIndex) count = currentPeriodIndex;

        _updateAllPastShareByPeriods(account);

        for (uint256 i = 1; i <= count; i++) {
            _updateAccountReward(account, currentPeriodIndex - i);
        }
        _claimReward(account);
    }

    // - external view functions - //

    /**
     * @notice Returns the length of feeTiers (or feePercentages, which is the same) to help users query feeTiers and feePercentage elements.
    */
    function feeLength(address _rewardToken) external view returns (uint256) {
        return feeTiers[_rewardToken].length;
    }

    /**
     * @notice Returns the claimable rewards for a given account for the specified periods.
     * @param account The account to check.
     * @param periodIndices The periods to check.
     */
    function claimableRewardWithIndices(address account, uint256[] memory periodIndices) external view returns (uint256 esGMXkeyRewardByGMXkey, uint256 esGMXkeyRewardByEsGMXkey, uint256 mpkeyRewardByGMXkey, uint256 mpkeyRewardByEsGMXkey, uint256 wethRewardByGMXkey, uint256 wethRewardByEsGMXkey, uint256 wethRewardByMPkey) {
        return _claimableReward(account, periodIndices);
    }

    /**
     * @notice Returns the claimable rewards for a given account for the recent periods.
     * @param account The account to check.
     * @param count The number of periods to check.
     */
    function claimableRewardWithCount(address account, uint256 count) external view returns (uint256 esGMXkeyRewardByGMXkey, uint256 esGMXkeyRewardByEsGMXkey, uint256 mpkeyRewardByGMXkey, uint256 mpkeyRewardByEsGMXkey, uint256 wethRewardByGMXkey, uint256 wethRewardByEsGMXkey, uint256 wethRewardByMPkey) {
        if (count > currentPeriodIndex) count = currentPeriodIndex;
        
        uint256[] memory periodIndices = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            periodIndices[i] = currentPeriodIndex - i - 1;
        }
        return _claimableReward(account, periodIndices);
    }

    // - external functions called by other key protocol contracts - //

    /**
     * @notice Initializes the last record for the receiver's deposit balance for esGmx and bnGmx.
     */
    function initTransferReceiver() external {
        require(IConverter(converter).isValidReceiver(msg.sender), "Rewards: receiver is not a valid receiver");
        require(!ITransferReceiver(msg.sender).accepted(), "Rewards: receiver has already accepted the transfer");
        uint256 stakedGmxAmount = IRewardTracker(stakedGmxTracker).depositBalances(msg.sender, gmx);
        lastDepositBalancesForReceivers[msg.sender][gmx] = stakedGmxAmount;
        uint256 stakedEsGmxAmount = IRewardTracker(stakedGmxTracker).depositBalances(msg.sender, esGmx);
        lastDepositBalancesForReceivers[msg.sender][esGmx] = stakedEsGmxAmount;
        uint256 stakedMpAmount = IRewardTracker(feeGmxTracker).depositBalances(msg.sender, bnGmx);
        lastDepositBalancesForReceivers[msg.sender][bnGmx] = stakedMpAmount;
        lastUpdatedAt[msg.sender] = block.timestamp;
        emit ReceiverInitialized(msg.sender, stakedGmxAmount, stakedEsGmxAmount, stakedMpAmount);
    }

    /**
     * @notice Updates all rewards for the transfer receiver contract and transfers the fees.
     * This function mints GMXkey & MPkey, updates common reward-related values,
     * and updates the receiver's value and records for future calls.
     * @dev Allows anyone to call this for a later upgrade of the transfer receiver contract,
     * which might enable anyone to update all rewards & receive fees.
     * @param feeTo The address that receives the fee.
     */
    function updateAllRewardsForTransferReceiverAndTransferFee(address feeTo) external nonReentrant whenNotPaused {
        require(IConverter(converter).isValidReceiver(msg.sender), "Rewards: msg.sender is not a valid receiver");
        require(ITransferReceiver(msg.sender).accepted(), "Rewards: only transferFeeReceiver can be used for this function");

        if (_isFirstInCurrentPeriod()) _initializePeriod();

        uint256 esGmxKeyAmountToMint = _updateNonEthRewardsForTransferReceiverAndTransferFee(msg.sender, esGMXkey, feeTo); // esGMXkey
        uint256 mpKeyAmountToMint = _updateNonEthRewardsForTransferReceiverAndTransferFee(msg.sender, MPkey, feeTo); // MPkey
        uint256 wethAmountToTransfer = _updateWethRewardsForTransferReceiverAndTransferFee(msg.sender, feeTo); // weth

        // Update the receiver's records for later call
        uint256 stakedGmxAmount = IRewardTracker(stakedGmxTracker).depositBalances(msg.sender, gmx);
        if (stakedGmxAmount > lastDepositBalancesForReceivers[msg.sender][gmx]) lastDepositBalancesForReceivers[msg.sender][gmx] = stakedGmxAmount;
        uint256 stakedEsGmxAmount = IRewardTracker(stakedGmxTracker).depositBalances(msg.sender, esGmx);
        if (stakedEsGmxAmount > lastDepositBalancesForReceivers[msg.sender][esGmx]) lastDepositBalancesForReceivers[msg.sender][esGmx] = stakedEsGmxAmount;
        uint256 stakedMpAmount = IRewardTracker(feeGmxTracker).depositBalances(msg.sender, bnGmx);
        if (stakedMpAmount > lastDepositBalancesForReceivers[msg.sender][bnGmx]) lastDepositBalancesForReceivers[msg.sender][bnGmx] = stakedMpAmount;
        lastUpdatedAt[msg.sender] = block.timestamp;

        emit RewardsCalculated(msg.sender, esGmxKeyAmountToMint, mpKeyAmountToMint, wethAmountToTransfer);
    }

    // - internal functions - //

    /**
     * Returns true if it's first reward update call in the current period (period based on the current block).
     */
    function _isFirstInCurrentPeriod() internal view returns (bool) {
        return currentPeriodIndex < block.timestamp / PERIOD;
    }

    /**
     * Initializes period and update reward-related values for the previous periods
     */
    function _initializePeriod() internal {
        // initialize total share values in staker if necessary
        IStaker(staker).updatePastTotalSharesByPeriod(GMXkey, type(uint256).max);
        IStaker(staker).updatePastTotalSharesByPeriod(esGMXkey, type(uint256).max);
        IStaker(staker).updatePastTotalSharesByPeriod(MPkey, type(uint256).max);

        uint256 totalShareForPrevPeriod = IStaker(staker).totalSharesPrevPeriod(GMXkey);
        if (totalShareForPrevPeriod > 0) {
            _applyCumulatedReward(GMXkey, esGMXkey, totalShareForPrevPeriod);
            _applyCumulatedReward(GMXkey, MPkey, totalShareForPrevPeriod);
            _applyCumulatedReward(GMXkey, weth, totalShareForPrevPeriod);
        }

        totalShareForPrevPeriod = IStaker(staker).totalSharesPrevPeriod(esGMXkey);
        if (totalShareForPrevPeriod > 0) {
            _applyCumulatedReward(esGMXkey, esGMXkey, totalShareForPrevPeriod);
            _applyCumulatedReward(esGMXkey, MPkey, totalShareForPrevPeriod);
            _applyCumulatedReward(esGMXkey, weth, totalShareForPrevPeriod);
        }

        totalShareForPrevPeriod = IStaker(staker).totalSharesPrevPeriod(MPkey);
        if (totalShareForPrevPeriod > 0) {
            _applyCumulatedReward(MPkey, weth, totalShareForPrevPeriod);
        }
        currentPeriodIndex = block.timestamp / PERIOD;
    }

    /**
     * Updates all the past share values for the given account.
     */
    function _updateAllPastShareByPeriods(address account) internal {
        IStaker(staker).updatePastUserSharesByPeriod(account, GMXkey, type(uint256).max);
        IStaker(staker).updatePastUserSharesByPeriod(account, esGMXkey, type(uint256).max);
        IStaker(staker).updatePastUserSharesByPeriod(account, MPkey, type(uint256).max);
    }

    /**
     * Claims all the calculated reward and fee for the given account.
     */
    function _claimReward(address account) internal {
        (uint256 esGMXKeyAmountByGMXkey, uint256 esGMXKeyFeeByGMXkey) = _calculateAndClaimRewardAndFee(account, GMXkey, esGMXkey);
        (uint256 mpKeyAmountByGMXKey, uint256 mpKeyFeeByGMXkey) = _calculateAndClaimRewardAndFee(account, GMXkey, MPkey);
        (uint256 esGmxKeyAmountByEsGMXkey, uint256 esGmxKeyFeeByEsGMXkey) = _calculateAndClaimRewardAndFee(account, esGMXkey, esGMXkey);
        (uint256 mpKeyAmountByEsGMXkey, uint256 mpKeyFeeByEsGMXkey) = _calculateAndClaimRewardAndFee(account, esGMXkey, MPkey);
        (uint256 ethAmountByGMXkey, uint256 ethFeeByGMXkey) = _calculateAndClaimRewardAndFee(account, GMXkey, weth);
        (uint256 ethAmountByEsGMXkey, uint256 ethFeeByEsGMXkey) = _calculateAndClaimRewardAndFee(account, esGMXkey, weth);
        (uint256 ethAmountByMPkey, uint256 ethFeeByMPkey) = _calculateAndClaimRewardAndFee(account, MPkey, weth);
        if (ethFeeByGMXkey > 0 || ethFeeByEsGMXkey > 0 || ethFeeByMPkey > 0) _transferAsETH(treasury, ethFeeByGMXkey + ethFeeByEsGMXkey + ethFeeByMPkey);
        if (ethAmountByGMXkey > 0 || ethAmountByEsGMXkey > 0 || ethAmountByMPkey > 0) _transferAsETH(account, ethAmountByGMXkey + ethAmountByEsGMXkey + ethAmountByMPkey);

        emit RewardClaimed(account, esGMXKeyAmountByGMXkey, esGMXKeyFeeByGMXkey, mpKeyAmountByGMXKey, mpKeyFeeByGMXkey, esGmxKeyAmountByEsGMXkey, esGmxKeyFeeByEsGMXkey, 
            mpKeyAmountByEsGMXkey, mpKeyFeeByEsGMXkey, ethAmountByGMXkey, ethFeeByGMXkey, ethAmountByEsGMXkey, ethFeeByEsGMXkey, ethAmountByMPkey, ethFeeByMPkey);
    }

    /**
     * Calculates fee from 'reward' variable and transfer reward & fee if 'isNonWeth' parameter is true
     */
    function _calculateAndClaimRewardAndFee(address account, address stakingToken, address rewardToken) internal returns (uint256 amount, uint256 fee) {
        amount = reward[account][stakingToken][rewardToken];
        if (amount > 0) {
            reward[account][stakingToken][rewardToken] = 0;
            fee = IStakingFeeCalculator(feeCalculator).calculateStakingFee(account, amount, stakingToken, rewardToken);
            amount -= fee;
            if (rewardToken != weth) { // if it's weth, weth rewards from GMXkey, esGMXkey and MPkey will be transferred together
                if (fee > 0) IERC20(rewardToken).safeTransfer(treasury, fee);
                IERC20(rewardToken).safeTransfer(account, amount);
            }
        }
    }

    /**
     * Updates the account's reward.
     */
    function _updateAccountReward(address account, uint256 periodIndex) internal {
        _updateAccountRewardForStakingTokenAndRewardToken(account, GMXkey, esGMXkey, periodIndex);
        _updateAccountRewardForStakingTokenAndRewardToken(account, GMXkey, MPkey, periodIndex);
        _updateAccountRewardForStakingTokenAndRewardToken(account, GMXkey, weth, periodIndex);
        _updateAccountRewardForStakingTokenAndRewardToken(account, esGMXkey, esGMXkey, periodIndex);
        _updateAccountRewardForStakingTokenAndRewardToken(account, esGMXkey, MPkey, periodIndex);
        _updateAccountRewardForStakingTokenAndRewardToken(account, esGMXkey, weth, periodIndex);
        _updateAccountRewardForStakingTokenAndRewardToken(account, MPkey, weth, periodIndex);
    }

    /**
     * Updates the account's reward & other reward-related values for the specified staking token and reward token.
     */
    function _updateAccountRewardForStakingTokenAndRewardToken(address account, address stakingToken, address rewardToken, uint256 periodIndex) internal {
        if (IStaker(staker).userSharesByPeriod(account, stakingToken, periodIndex) > 0) {
            uint256 delta = _calculateReward(stakingToken, rewardToken, account, periodIndex);
            if (delta > 0) {
                reward[account][stakingToken][rewardToken] += delta;
                lastRewardPerUnit[account][stakingToken][rewardToken][periodIndex] = rewardPerUnit[stakingToken][rewardToken][periodIndex];
            }
        }
    }

    /**
     * Calculates the reward for the specified staking token and reward token that is claimable by the account.
     */
    function _calculateReward(address stakingToken, address rewardToken, address account, uint256 periodIndex) internal view returns (uint256) {
        return Math.mulDiv(
            rewardPerUnit[stakingToken][rewardToken][periodIndex] - lastRewardPerUnit[account][stakingToken][rewardToken][periodIndex], 
            IStaker(staker).userSharesByPeriod(account, stakingToken, periodIndex),
            PRECISION
        );
    }

    /**
     * Updates the esGMX, MP rewards from the transfer receiver contract & transfer fee.
     * @param receiver The receiver contract from which the rewards originate.
     * @param rewardToken The reward token to update.
     * @param feeTo The address to which the transfer fee is sent.
     */
    function _updateNonEthRewardsForTransferReceiverAndTransferFee(address receiver, address rewardToken, address feeTo) internal returns (uint256 amountToMint) {
        if (ITransferReceiver(receiver).isForMpKey()) return 0;
        uint256 _depositBalance = _getDepositBalancesForReceiver(receiver, rewardToken);
        uint256 _lastDepositBalance = lastDepositBalancesForReceivers[receiver][_getStakedToken(rewardToken)];
        if (_depositBalance > _lastDepositBalance) {
            amountToMint = _depositBalance - _lastDepositBalance;

            (uint256 amount, uint256 fee) = _calculateFee(amountToMint, _getFeeRate(receiver, rewardToken));

            // Distribute esGMXkey or MPkey in the ratio of GMX and esGMX
            uint256 gmxBalance = lastDepositBalancesForReceivers[receiver][gmx];
            uint256 esGmxBalance = lastDepositBalancesForReceivers[receiver][esGmx];

            uint256 amountByEsGMX = Math.mulDiv(amount, esGmxBalance, gmxBalance + esGmxBalance);

            uint256 _lastUpdatedAt = lastUpdatedAt[receiver];
            _updateNonSharedReward(GMXkey, rewardToken, amount - amountByEsGMX, _lastUpdatedAt);
            _updateNonSharedReward(esGMXkey, rewardToken, amountByEsGMX, _lastUpdatedAt);

            IERC20(rewardToken).mint(address(this), amount);
            if (fee > 0) IERC20(rewardToken).mint(feeTo, fee);
        }
    }

    /**
     * Updates the WETH rewards from the transfer receiver contract & transfer fee.
     * @param receiver The receiver contract from which the rewards originate.
     * @param feeTo The address to which the transfer fee is sent.
     */
    function _updateWethRewardsForTransferReceiverAndTransferFee(address receiver, address feeTo) internal returns (uint256 amountToTransfer) {
        amountToTransfer = IERC20(weth).allowance(receiver, address(this));
        // use allowance to prevent 'weth transfer attack' by transferring any amount of weth to the receiver contract
        if (amountToTransfer > 0) {
            IERC20(weth).safeTransferFrom(receiver, address(this), amountToTransfer);
            // Update common reward-related values
            (uint256 amount, uint256 fee) = _calculateFee(amountToTransfer, _getFeeRate(receiver, weth));
            _updateWethReward(amount, receiver);
            if (fee > 0) _transferAsETH(feeTo, fee);
        }
    }

    /**
     * Records the calculated reward amount per unit staking amount.
     * @param stakingToken Staked token
     * @param rewardToken Token paid as a reward
     * @param amount Total claimable reward amount
     * @param _lastUpdatedAt The last time the reward was updated
     */
    function _updateNonSharedReward(address stakingToken, address rewardToken, uint256 amount, uint256 _lastUpdatedAt) internal {
        if (_lastUpdatedAt >= currentPeriodIndex * PERIOD) {
            cumulatedReward[stakingToken][rewardToken] += amount;
        } else {
            uint256 denominator = block.timestamp - _lastUpdatedAt;
            uint256 firstIdx = _lastUpdatedAt / PERIOD + 1;
            uint256 lastIdx = block.timestamp / PERIOD - 1;
            uint256 amountLeft = amount;
            uint256 amountToDistribute = 0;
            uint256 totalShare = 0;
            if (lastIdx + 2 - firstIdx > maxPeriodsToUpdateRewards) {
                firstIdx = lastIdx - maxPeriodsToUpdateRewards + 1;
                denominator = maxPeriodsToUpdateRewards * PERIOD + block.timestamp - block.timestamp / PERIOD * PERIOD;
            } else {
                amountToDistribute = amount * ((_lastUpdatedAt / PERIOD + 1) * PERIOD - _lastUpdatedAt) / denominator;
                amountLeft -= amountToDistribute;
                totalShare = IStaker(staker).totalSharesByPeriod(stakingToken, _lastUpdatedAt / PERIOD);
                if (totalShare == 0) {
                    cumulatedReward[stakingToken][rewardToken] += amountToDistribute;
                } else {
                    rewardPerUnit[stakingToken][rewardToken][_lastUpdatedAt / PERIOD] += Math.mulDiv(amountToDistribute, PRECISION, totalShare);
                }
            }

            for (uint256 i = firstIdx; i <= lastIdx; i++) {
                amountToDistribute = amount * PERIOD / denominator;
                amountLeft -= amountToDistribute;
                totalShare = IStaker(staker).totalSharesByPeriod(stakingToken, i);
                if (totalShare == 0) {
                    cumulatedReward[stakingToken][rewardToken] += amountToDistribute;
                } else {
                    rewardPerUnit[stakingToken][rewardToken][i] += Math.mulDiv(amountToDistribute, PRECISION, totalShare);
                }
            }

            cumulatedReward[stakingToken][rewardToken] += amountLeft;
        }
    }

    /**
     * Applies the cumulated reward to the previous period.
     */
    function _applyCumulatedReward(address stakingToken, address rewardToken, uint256 totalShareForPrevPeriod) internal {
        rewardPerUnit[stakingToken][rewardToken][block.timestamp / PERIOD - 1] += Math.mulDiv(cumulatedReward[stakingToken][rewardToken], PRECISION, totalShareForPrevPeriod);
        cumulatedReward[stakingToken][rewardToken] = 0;
    }

    /**
     * Records the reward amount per unit staking amount for WETH rewards paid to both GMXkey, esGMXkey and MPkey.
     * @dev In the case of WETH rewards paid to GMXkey, esGMXkey and MPkey, the reward amount for each cannot be known.
     * Therefore, they are calculated together at once.
     * @param amount Total claimable WETH amount
     * @param receiver The receiver contract from which the rewards originate.
     */
    function _updateWethReward(uint256 amount, address receiver) internal {
        uint256 _lastUpdatedAt = lastUpdatedAt[receiver];
        if (ITransferReceiver(receiver).isForMpKey()) {
            _updateNonSharedReward(MPkey, weth, amount, _lastUpdatedAt);
            return;
        }
        uint256 gmxStaked = lastDepositBalancesForReceivers[receiver][gmx];
        uint256 esGmxStaked = lastDepositBalancesForReceivers[receiver][esGmx];
        uint256 mpStaked = lastDepositBalancesForReceivers[receiver][bnGmx];
        uint256 totalStaked = gmxStaked + esGmxStaked + mpStaked;
        uint256 amountForMpKey = Math.mulDiv(amount, mpStaked, totalStaked);
        uint256 amountForEsGmxKey = Math.mulDiv(amount, esGmxStaked, totalStaked);
        uint256 amountForGmxKey = amount - amountForEsGmxKey - amountForMpKey;
        _updateNonSharedReward(GMXkey, weth, amountForGmxKey, _lastUpdatedAt);
        _updateNonSharedReward(esGMXkey, weth, amountForEsGmxKey, _lastUpdatedAt);
        _updateNonSharedReward(MPkey, weth, amountForMpKey, _lastUpdatedAt);
    }

    /**
     * Returns the claimable rewards for a given account for the specified periods.
     * @param account The account to check.
     * @param periodIndices The period indices to check.
     * @return esGMXkeyRewardByGMXkey The claimable esGMXkey reward by GMXkey.
     * @return esGMXkeyRewardByEsGMXkey The claimable esGMXkey reward by esGMXkey.
     * @return mpkeyRewardByGMXkey The claimable MPkey reward by GMXkey.
     * @return mpkeyRewardByEsGMXkey The claimable MPkey reward by esGMXkey.
     * @return wethRewardByGMXkey The claimable WETH reward by GMXkey.
     * @return wethRewardByEsGMXkey The claimable WETH reward by esGMXkey.
     * @return wethRewardByMPkey The claimable WETH reward by MPkey.
     */
    function _claimableReward(address account, uint256[] memory periodIndices) internal view returns (uint256 esGMXkeyRewardByGMXkey, uint256 esGMXkeyRewardByEsGMXkey, uint256 mpkeyRewardByGMXkey, uint256 mpkeyRewardByEsGMXkey, uint256 wethRewardByGMXkey, uint256 wethRewardByEsGMXkey, uint256 wethRewardByMPkey) {
        esGMXkeyRewardByGMXkey = reward[account][GMXkey][esGMXkey];
        esGMXkeyRewardByEsGMXkey = reward[account][esGMXkey][esGMXkey];
        mpkeyRewardByGMXkey = reward[account][GMXkey][MPkey];
        mpkeyRewardByEsGMXkey = reward[account][esGMXkey][MPkey];
        wethRewardByGMXkey = reward[account][GMXkey][weth];
        wethRewardByEsGMXkey = reward[account][esGMXkey][weth];
        wethRewardByMPkey = reward[account][MPkey][weth];
        for (uint256 i = 0; i < periodIndices.length; i++) {
            uint256 periodIndex = periodIndices[i];
            esGMXkeyRewardByGMXkey += _calculateReward(GMXkey, esGMXkey, account, periodIndex);
            esGMXkeyRewardByEsGMXkey += _calculateReward(esGMXkey, esGMXkey, account, periodIndex);
            mpkeyRewardByGMXkey += _calculateReward(GMXkey, MPkey, account, periodIndex);
            mpkeyRewardByEsGMXkey += _calculateReward(esGMXkey, MPkey, account, periodIndex);
            wethRewardByGMXkey += _calculateReward(GMXkey, weth, account, periodIndex);
            wethRewardByEsGMXkey += _calculateReward(esGMXkey, weth, account, periodIndex);
            wethRewardByMPkey += _calculateReward(MPkey, weth, account, periodIndex);
        }
        esGMXkeyRewardByGMXkey -= IStakingFeeCalculator(feeCalculator).calculateStakingFee(account, esGMXkeyRewardByGMXkey, GMXkey, esGMXkey);
        esGMXkeyRewardByEsGMXkey -= IStakingFeeCalculator(feeCalculator).calculateStakingFee(account, esGMXkeyRewardByEsGMXkey, esGMXkey, esGMXkey);
        mpkeyRewardByGMXkey -= IStakingFeeCalculator(feeCalculator).calculateStakingFee(account, mpkeyRewardByGMXkey, GMXkey, MPkey);
        mpkeyRewardByEsGMXkey -= IStakingFeeCalculator(feeCalculator).calculateStakingFee(account, mpkeyRewardByEsGMXkey, esGMXkey, MPkey);
        wethRewardByGMXkey -= IStakingFeeCalculator(feeCalculator).calculateStakingFee(account, wethRewardByGMXkey, GMXkey, weth);
        wethRewardByEsGMXkey -= IStakingFeeCalculator(feeCalculator).calculateStakingFee(account, wethRewardByEsGMXkey, esGMXkey, weth);
        wethRewardByMPkey -= IStakingFeeCalculator(feeCalculator).calculateStakingFee(account, wethRewardByMPkey, MPkey, weth);
    }

    function _getFeeRate(address receiver, address _rewardToken) internal view returns (uint16) {
        uint256[] memory _feeTiers = feeTiers[_rewardToken];
        if (_feeTiers.length == 0) return 0;

        uint16[] memory _feePercentages = feePercentages[_rewardToken];

        uint256 panGmxAmount = _getLastPanGmxDepositBalances(receiver);
        uint16 _feePercentage = _feePercentages[_feePercentages.length - 1];
        for (uint256 i = 0; i < _feeTiers.length; i++) {
            if (panGmxAmount >= _feeTiers[i]) {
                _feePercentage = _feePercentages[i];
                break;
            }
        }

        return _feePercentage;
    }

    function _getLastPanGmxDepositBalances(address receiver) internal view returns (uint256) {
        return lastDepositBalancesForReceivers[receiver][gmx] + lastDepositBalancesForReceivers[receiver][esGmx];
    }

    /**
     * Queries the staking amount of the token corresponding to the rewardToken.
     * @param receiver The receiver contract targeted to check how much stakingToken has been accumulated for the given rewardToken.
     * @param rewardToken Which rewardToken's stakingToken amount is being queried.
     */
    function _getDepositBalancesForReceiver(address receiver, address rewardToken) internal view returns (uint256) {
        if (rewardToken == GMXkey || rewardToken == esGMXkey) {
            return IRewardTracker(stakedGmxTracker).depositBalances(receiver, _getStakedToken(rewardToken));
        } else { // rewardToken == MPkey
            return IRewardTracker(feeGmxTracker).depositBalances(receiver, _getStakedToken(rewardToken));
        }
    }

    /**
     * Queries the token staked at GMX protocol, corresponding to the rewardToken.
     */
    function _getStakedToken(address rewardToken) internal view returns (address) {
        if (rewardToken == GMXkey) {
            return gmx;
        } else if (rewardToken == esGMXkey) {
            return esGmx;
        } else { // rewardToken == MPkey
            return bnGmx;
        }
    }

    /**
     * Calculates the reward amount after fee transfer and its fee.
     */
    function _calculateFee(uint256 _amount, uint16 _feeRate) internal pure returns (uint256, uint256) {
        uint256 _fee = _amount * _feeRate / FEE_PERCENTAGE_BASE;
        return (_amount - _fee, _fee);
    }

    /**
     * Transfers the specified amount as ETH to the specified address.
     */
    function _transferAsETH(address to, uint256 amount) internal {
        // amount is already non-zero

        IWETH(weth).withdraw(amount);
        (bool success,) = to.call{value : amount}("");
        require(success, "Transfer failed");
    }

    receive() external payable {
        require(msg.sender == weth);
    }
}