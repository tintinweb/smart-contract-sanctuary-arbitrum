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


/**
 * @title Staker
 * @author Key Finance
 * @notice
 * Staker is a contract that allows users to stake GMXkey, esGMXkey and MPkey tokens and calculate shares.
 * Shares are proportional to time and volume and are settled at weekly intervals.
 */
contract Staker is IStaker, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // constants
    uint256 public constant PERIOD = 1 weeks;

    // key protocol contracts
    address public immutable GMXkey;
    address public immutable esGMXkey;
    address public immutable MPkey;

    // state variables
    mapping(address => uint256) public totalBalance; // by token
    mapping(address => mapping(address => uint256)) public userBalance; // by account and token

    mapping(address => mapping(uint256 => uint256)) public totalSharesByPeriod; // by token and period
    mapping(address => mapping(address => mapping(uint256 => uint256))) internal _userSharesByPeriod; // by account and token and period

    mapping(address => uint256) public latestTotalShares; // when latest updated, by token
    mapping(address => uint256) public latestTotalSharesUpdatedAt; // by token

    mapping(address => mapping(address => uint256)) public latestUserShares; // when latest updated, by account and token
    mapping(address => mapping(address => uint256)) public latestUserSharesUpdatedAt; // by account and token

    constructor(address _admin, address _GMXkey, address _esGMXkey, address _MPkey) Pausable(_admin) {
        require(_GMXkey != address(0), "Staker: GMXkey is the zero address");
        require(_esGMXkey != address(0), "Staker: esGMXkey is the zero address");
        require(_MPkey != address(0), "Staker: MPkey is the zero address");
        GMXkey = _GMXkey;
        esGMXkey = _esGMXkey;
        MPkey = _MPkey;
    }

    // - external state-changing functions - //

    /**
     * @notice Stakes GMXkey, esGMXkey, or MPkey tokens.
     * @param token Token to stake.
     * @param amount Amount to unstake.
     */
    function stake(address token, uint256 amount) external nonReentrant whenNotPaused {
        require(_isStakable(token), "Staker: token is not stakable");
        require(amount > 0, "Staker: amount is 0");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // update totalSharesByPeriod
        _updateTotalSharesByPeriod(token);

        // update userSharesByPeriod
        _updateUserSharesByPeriod(token, msg.sender);

        totalBalance[token] += amount;
        unchecked {
            userBalance[msg.sender][token] += amount;
        }

        emit Staked(msg.sender, token, amount);
    }

    /**
     * @notice Unstakes GMXkey, esGMXkey or MPkey tokens.
     * @param token Token to unstake.
     * @param amount Amount to unstake.
     */
    function unstake(address token, uint256 amount) external nonReentrant {
        require(_isStakable(token), "Staker: token is not stakable");
        require(amount > 0, "Staker: amount is 0");

        uint256 _balance = userBalance[msg.sender][token];
        require(_balance >= amount, "Staker: insufficient balance");

        // update totalSharesByPeriod
        _updateTotalSharesByPeriod(token);

        // update userSharesByPeriod
        _updateUserSharesByPeriod(token, msg.sender);

        unchecked {
            totalBalance[token] -= amount;
            userBalance[msg.sender][token] = _balance - amount;
        }

        IERC20(token).safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, token, amount);
    }

    /**
     * @notice Updates total share values in the past.
     * @param token Token to update total share values in the past.
     * @param loop The number of periods to update.
     */
    function updatePastTotalSharesByPeriod(address token, uint256 loop) external {
        _updatePastTotalSharesByPeriod(token, loop);
    }

    /**
     * @notice Updates user share values in the past.
     * @param token Token to update user share values in the past.
     * @param account Account to update user share values in the past.
     * @param loop The number of periods to update.
     */
    function updatePastUserSharesByPeriod(address account, address token, uint256 loop) external {
        _updatePastUserSharesByPeriod(token, account, loop);
    }

    // - external view functions - //

    /**
     * @notice Returns the total share of the previous period.
     * @param token Token to look up
     */
    function totalSharesPrevPeriod(address token) external view returns (uint256) {
        return totalSharesByPeriod[token][_getPeriodNumber(block.timestamp) - 1];
    }

    /**
     * @notice Returns the user share for the specified period.
     * @dev This should be used for the previous periods.
     * @param token Token to look up
     * @param account Account to look up
     * @param periodIndex Period index to look up
     */
    function userSharesByPeriod(address account, address token, uint256 periodIndex) external view returns (uint256) {
        if ((periodIndex + 1) * PERIOD > block.timestamp) return 0;

        uint256 _latestUpdatedPeriod = _getPeriodNumber(latestUserSharesUpdatedAt[account][token]);
        if (periodIndex < _latestUpdatedPeriod) {
            return _userSharesByPeriod[account][token][periodIndex];
        } else if (periodIndex == _latestUpdatedPeriod) {
            return latestUserShares[account][token] + _getShare(userBalance[account][token], latestUserSharesUpdatedAt[account][token], (_latestUpdatedPeriod + 1) * PERIOD);
        } else {
            return _getShare(userBalance[account][token], PERIOD);
        }
    }

    // - internal functions - //

    /**
     * Checks if the token is stakeable.
     * @param token Token address to check.
     */
    function _isStakable(address token) internal view returns (bool) {
        return token == GMXkey || token == esGMXkey || token == MPkey;
    }

    function _updateTotalSharesByPeriod(address token) internal {
        _updatePastTotalSharesByPeriod(token, type(uint256).max);
    }

    function _updatePastTotalSharesByPeriod(address token, uint256 loop) internal {
        _updatePastSharesByPeriod(
            token,
            totalBalance[token],
            totalSharesByPeriod[token],
            latestTotalShares,
            latestTotalSharesUpdatedAt,
            loop
        );
    }

    function _updateUserSharesByPeriod(address token, address account) internal {
        _updatePastUserSharesByPeriod(token, account, type(uint256).max);
    }

    function _updatePastUserSharesByPeriod(address token, address account, uint256 loop) internal {
        _updatePastSharesByPeriod(
            token,
            userBalance[account][token],
            _userSharesByPeriod[account][token],
            latestUserShares[account],
            latestUserSharesUpdatedAt[account],
            loop
        );
    }

    /**
     * Updates sharesByPeriod in the past.
     */
    function _updatePastSharesByPeriod
    (
        address token,
        uint256 _balance,
        mapping(uint256 => uint256) storage _sharesByPeriod,
        mapping(address => uint256) storage _latestShares,
        mapping(address => uint256) storage _latestSharesUpdatedAt,
        uint256 loop
    ) internal {
        if (loop == 0) revert("loop must be greater than 0");

        if (_latestSharesUpdatedAt[token] == 0) {
            _latestSharesUpdatedAt[token] = block.timestamp;
            return;
        }

        uint256 firstIndex = _getPeriodNumber(_latestSharesUpdatedAt[token]);
        uint256 lastIndex = _getPeriodNumber(block.timestamp) - 1;
        if (loop != type(uint256).max && lastIndex >= firstIndex + loop) {
            lastIndex = firstIndex + loop - 1;
        }

        if (firstIndex > lastIndex) { // called again in the same period
            _latestShares[token] += _getShare(_balance, _latestSharesUpdatedAt[token], block.timestamp);
            _latestSharesUpdatedAt[token] = block.timestamp;
        } else { // when the last updated period passed, update sharesByPeriod of the period
            _sharesByPeriod[firstIndex] = _latestShares[token] + _getShare(_balance, _latestSharesUpdatedAt[token], (firstIndex + 1) * PERIOD);
            for (uint256 i = firstIndex + 1; i <= lastIndex; i++) {
                _sharesByPeriod[i] = _getShare(_balance, PERIOD);
            }

            if (loop != type(uint256).max) {
                _latestShares[token] = 0;
                _latestSharesUpdatedAt[token] = (lastIndex + 1) * PERIOD;
            } else {
                _latestShares[token] = _getShare(_balance, (lastIndex + 1) * PERIOD, block.timestamp);
                _latestSharesUpdatedAt[token] = block.timestamp;
            }
        }
    }

    function _getPeriodNumber(uint256 _time) internal pure returns (uint256) {
        return _time / PERIOD;
    }

    function _getShare(uint256 _balance, uint256 _startTime, uint256 _endTime) internal pure returns (uint256) {
        return _getShare(_balance, (_endTime - _startTime));
    }

    function _getShare(uint256 _balance, uint256 _duration) internal pure returns (uint256) {
        return _balance * _duration;
    }
}